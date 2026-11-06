require_relative '../utils/config_loader'
# rack-test cannot parse the empty "domain=" cookie attribute an empty
# cookie_domain produces; the cookie domain does not matter here.
CONFIG['app']['cookie_domain'] = nil
require_relative '../utils/spec_helper'
require 'json'
require 'models/space_hour'
require 'models/lockout'
require 'models/tool'
require 'models/tool_log'

# Specs for routes/public_api.rb. Each example builds its own data inside a
# transaction that is rolled back, so they run against any database with the
# schema loaded: `bundle exec rspec spec/public_api_spec.rb`.
describe 'Public API' do
  def app
    Sinatra::Application
  end

  around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end

  def json
    JSON.parse(last_response.body)
  end

  def local(date, hour, minute = 0)
    Time.zone.local(date.year, date.month, date.day, hour, minute)
  end

  def open_hours(date, *blocks)
    SpaceHour.create!(service_space_id: SS_ID, day_of_week: date.wday, effective_date: local(date, 0),
                      one_off: true, hours: blocks.map { |s, e| { status: 'open', start: s * 60, end: e * 60 } })
  end

  # Monday 2031-03-10: open 9:00-17:00. Tuesday: open 9:00-12:00.
  let(:monday) { Date.new(2031, 3, 10) }
  let(:tuesday) { Date.new(2031, 3, 11) }
  let(:member) do
    User.create!(service_space_id: SS_ID, username: 'api-spec-member', email: 'api-spec-member@example.com',
                 first_name: 'Spec', last_name: 'Member')
  end
  let(:tool) do
    Resource.create!(service_space_id: SS_ID, name: 'API Spec Laser', category_id: 4, is_reservable: true,
                     needs_authorization: true, time_slot_type: 'range', min_minutes_per_reservation: 30,
                     max_minutes_per_reservation: 120, increment_minutes_per_reservation: 30,
                     max_reservations_per_user: 2, is_24_hour: false, INOP: false)
  end
  let(:event) do
    Event.create!(title: 'Spec Laser Training', service_space_id: SS_ID, start_time: local(monday, 14),
                  end_time: local(monday, 15), is_private: 0)
  end

  before do
    open_hours(monday, [9, 17])
    open_hours(tuesday, [9, 12])
    Reservation.create!(resource_id: tool.id, user_id: member.id, is_training: false,
                        start_time: local(monday, 10), end_time: local(monday, 11))
    Reservation.create!(resource_id: tool.id, user_id: member.id, is_training: false,
                        start_time: local(monday, 13), end_time: local(monday, 13, 30))
    Reservation.create!(resource_id: tool.id, event_id: event.id, is_training: true,
                        start_time: local(monday, 14), end_time: local(monday, 15))
    Lockout.create!(resource_id: tool.id, started_on: local(monday, 15, 30), released_on: local(monday, 16))
  end

  it 'lists tools with their reservation rules and CORS enabled' do
    get '/api/v1/tools'
    expect(last_response).to be_ok
    expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
    listed = json['tools'].find { |t| t['id'] == tool.id }
    expect(listed).to include('name' => 'API Spec Laser', 'status' => 'operational', 'reservable' => true,
                              'requires_authorization' => true, 'reservation_lengths_minutes' => [30, 60, 90, 120],
                              'max_upcoming_reservations_per_user' => 2)
  end

  it 'reports a tool with an active lockout as locked out' do
    Lockout.create!(resource_id: tool.id, started_on: Time.now - 3600, released_on: nil)
    get "/api/v1/tools/#{tool.id}"
    expect(json['tool']['status']).to eq('locked_out')
    expect(json['tool']['lockouts'].first['ends_at']).to be_nil
  end

  it 'only serves tools of this service space' do
    other = Resource.create!(service_space_id: SS_ID == 1 ? 8 : 1, name: 'Elsewhere', is_reservable: true)
    get "/api/v1/tools/#{other.id}"
    expect(last_response.status).to eq(404)
    expect(json['error']).to eq('tool not found')
  end

  it 'returns reservations as anonymous time blocks' do
    get "/api/v1/tools/#{tool.id}/reservations", start: '2031-03-10', end: '2031-03-10'
    expect(last_response).to be_ok
    reservations = json['reservations']
    expect(reservations.map { |r| [r['starts_at'], r['minutes'], r['type']] }).to eq([
      ['2031-03-10T10:00:00-05:00', 60, 'member'],
      ['2031-03-10T13:00:00-05:00', 30, 'member'],
      ['2031-03-10T14:00:00-05:00', 60, 'training']
    ])
    expect(reservations.last['event']).to eq('id' => event.id, 'title' => 'Spec Laser Training')
    expect(last_response.body).not_to include('user', member.username, member.email)
  end

  it 'hides the event of a private training' do
    event.update!(is_private: 1)
    get '/api/v1/reservations', start: '2031-03-10', end: '2031-03-10', tool_id: tool.id
    expect(json['reservations'].last).to include('type' => 'training', 'event' => nil)
  end

  it 'computes free time from open hours, reservations and lockouts' do
    get "/api/v1/tools/#{tool.id}/availability", start: '2031-03-10', end: '2031-03-10'
    expect(last_response).to be_ok
    day = json['days'].first
    expect(day['open']).to eq([{ 'starts_at' => '2031-03-10T09:00:00-05:00', 'ends_at' => '2031-03-10T17:00:00-05:00' }])
    expect(day['free'].map { |f| [f['starts_at'][11, 5], f['ends_at'][11, 5], f['minutes']] }).to eq([
      ['09:00', '10:00', 60], ['11:00', '13:00', 120], ['13:30', '14:00', 30], ['15:00', '15:30', 30], ['16:00', '17:00', 60]
    ])
  end

  it 'drops free gaps shorter than the shortest reservation' do
    tool.update!(min_minutes_per_reservation: 60)
    get "/api/v1/tools/#{tool.id}/availability", start: '2031-03-10', end: '2031-03-10'
    expect(json['days'].first['free'].map { |f| f['minutes'] }).to eq([60, 120, 60])
  end

  it 'computes utilization against reservable time' do
    get "/api/v1/tools/#{tool.id}/utilization", start: '2031-03-10', end: '2031-03-11'
    expect(last_response).to be_ok
    expect(json['summary']).to eq(
      'open_minutes' => 660, 'lockout_minutes' => 30, 'reservable_minutes' => 630,
      'reserved_minutes' => 90, 'training_minutes' => 60, 'utilization' => 0.2381,
      'reservations' => 2, 'average_reservation_minutes' => 45, 'training_sessions' => 1, 'unique_members' => 1
    )
    expect(json['series'].map { |day| [day['start'], day['reservable_minutes'], day['utilization']] }).to eq([
      ['2031-03-10', 450, 0.3333], ['2031-03-11', 180, 0.0]
    ])
  end

  it 'summarises utilization per category and over weeks' do
    get '/api/v1/utilization', start: '2031-03-10', end: '2031-03-11', tool_id: tool.id, interval: 'week'
    expect(last_response).to be_ok
    expect(json['tools'].map { |t| t['id'] }).to eq([tool.id])
    expect(json['totals']['utilization']).to eq(0.2381)
    expect(json['categories'].map { |c| [c['id'], c['tools']] }).to eq([[4, 1]])
    expect(json['series'].map { |w| [w['start'], w['end'], w['reserved_minutes']] }).to eq([['2031-03-10', '2031-03-11', 90]])
  end

  it 'rejects bad parameters' do
    get '/api/v1/reservations', start: '03/10/2031'
    expect(last_response.status).to eq(400)
    get '/api/v1/reservations', start: '2031-03-10', end: '2031-03-01'
    expect(json['error']).to eq('end must not be before start')
    get '/api/v1/reservations', start: '2031-01-01', end: '2031-12-31'
    expect(last_response.status).to eq(400)
    get '/api/v1/utilization', interval: 'hour'
    expect(last_response.status).to eq(400)
    get '/api/v1/nope'
    expect(last_response.status).to eq(404)
    expect(json['error']).to start_with('no such endpoint')
  end

  it 'answers requests referred by other sites' do
    get '/api/v1/tools', {}, 'HTTP_REFERER' => 'https://example.org/page'
    expect(last_response).to be_ok
  end

  it 'leaves the HTML not-found page alone outside the API' do
    get '/no-such-page/'
    expect(last_response.status).to eq(404)
    expect(last_response.body).to include('That page was not found.')
  end

  describe 'checkout tools' do
    let(:monday) { Date.new(2020, 1, 6) }
    let(:tuesday) { Date.new(2020, 1, 7) }
    let(:other_member) do
      User.create!(service_space_id: SS_ID, username: 'api-spec-other', email: 'api-spec-other@example.com')
    end
    let(:drill) do
      Tool.create!(service_space_id: SS_ID, tool_name: 'API Spec Drill', serial_number: 'API-SPEC-0001',
                   last_checked_in: local(monday, 12), last_checked_out: local(tuesday, 10))
    end

    before do
      [[member, local(monday, 10), false], [member, local(monday, 12), true], [other_member, local(tuesday, 10), false]]
        .each do |user, time, checking_in|
          ToolLog.create!(tool_id: drill.id, tool_name: drill.tool_name, checkout_user_id: user.id,
                          checked_date: time, is_checking_in: checking_in)
        end
    end

    it 'lists status without saying who has a tool' do
      get '/api/v1/checkout_tools'
      listed = json['checkout_tools'].find { |t| t['id'] == drill.id }
      expect(listed).to include('status' => 'checked_out', 'checked_out_since' => '2020-01-07T10:00:00-06:00')
      expect(last_response.body).not_to include(member.username)
    end

    it 'measures checkouts; one never checked in lasts until now' do
      get '/api/v1/checkout_tools/utilization', start: '2020-01-06', end: '2020-01-07'
      report = json['checkout_tools'].find { |t| t['id'] == drill.id }
      expect(report).to eq(
        'id' => drill.id, 'name' => 'API Spec Drill', 'checkouts' => 2, 'checked_out_minutes' => 960,
        'average_checkout_minutes' => 120, 'unique_borrowers' => 2, 'open_minutes' => 660, 'utilization' => 0.3636
      )
    end
  end
end

describe Intervals do
  it 'merges, intersects and subtracts' do
    expect(Intervals.union([[5, 8], [1, 3], [2, 4]])).to eq([[1, 4], [5, 8]])
    expect(Intervals.intersect([[0, 10]], [[2, 3], [8, 12]])).to eq([[2, 3], [8, 10]])
    expect(Intervals.subtract([[0, 10]], [[2, 3], [8, Float::INFINITY]])).to eq([[0, 2], [3, 8]])
  end
end

describe ToolSchedule do
  it 'treats Design Hub 24-hour tools as reservable all day, including DST days' do
    tool = Resource.new(service_space_id: 8, is_24_hour: true)
    expect(ToolSchedule.twenty_four_hour?(tool)).to be(true)
    expect(ToolSchedule.twenty_four_hour?(Resource.new(service_space_id: 1, is_24_hour: true))).to be(false)
    s, e = ToolSchedule.new(8).open_intervals(Date.new(2031, 3, 9), true).first
    expect(e - s).to eq(23 * 3600) # clocks spring forward that night
  end

  it 'offers the reservation lengths the reserve form does' do
    expect(ToolSchedule.reservation_lengths(Resource.new(time_slot_type: 'exact', minutes_per_reservation: 60))).to eq([60])
    expect(ToolSchedule.reservation_lengths(Resource.new(time_slot_type: 'exact'))).to eq([])
    expect(ToolSchedule.reservation_lengths(Resource.new(time_slot_type: 'range', min_minutes_per_reservation: 0,
                                                         max_minutes_per_reservation: 60,
                                                         increment_minutes_per_reservation: 30))).to eq([30, 60])
    expect(ToolSchedule.reservation_lengths(Resource.new(time_slot_type: nil))).to eq([15, 30, 45, 60, 90, 120])
  end
end
