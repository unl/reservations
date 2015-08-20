require 'active_record'
require 'models/service_space'
require 'models/resource'

class AddToolsFromDocument < ActiveRecord::Migration
	def up
		ss = ServiceSpace.where(:name => "Innovation Studio").first

		[
			['Oscilloscope', 'Rigo DS1054'],
			['DC Power Supply', 'Gwinstek GPD-3303S'],
			['Soldering Iron', 'Hakko FX-88D'],
			['SMD Rework Station', 'Spark Fun 303D'],
			['Vacuum Pen', 'Virtual Industries Inc. SMD-VAC HP'],
			['Lead Free Solder Pot', 'SMT max ML-52T5'],
			['Function/Arbitrary Waveform Generator', 'Rigol DG1022'],
			['96" x 48" CNC Router', 'ShopBot PRSalpha'],
			['Drill Press', 'Clausing 20'],
			['Sliding Compound Miter Saw', 'Festrool Kapex KS 120 EB'],
			['Table Saw', 'Saw Stop 10" Industrial Grade Cabinet Saw'],
			['Laser Cutter', 'Epilog Fusion 32'],
			['Large Format Printer', 'Epson Style Pro 4900'],
			['3D Filament Desktop Printer', 'Ultimaker 2'],
			['6" Industrial Belt Sander', 'Jet Stock # 414600'],
			['12" Industrial Disc Sander', 'Jet Stock # 414602'],
			['18" Variable Speed Scroll Saw', 'Delta'],
			['18" Wood Band Saw', 'Laguna'],
			['Panel Saw', 'Safety Speed'],
			['3D Filament Desktop Printer', 'Stratasys Mojo'],
			['Air Assist Pump (laser cutter)', 'GAST'],
			['Desktop 3D Scanner', 'Next Engine'],
			['Vinyl Cutter', 'Graphtec Cutting Plotter CE6000-60'],
			['Industrial Sewing Machine', 'JUKI # 2DODE00141'],
			['Standard Sewing Machine', 'Bernina 830'],
			['Standard Sewing Machine', 'Bernina 803'],
			['Ironing Station', '']
		].each do |arr|
			Resource.create(
				:name => arr[0],
				:resource_type => arr[0],
				:model => arr[1],
				:service_space_id => ss.id,
				:needs_authorization => true,
				:needs_approval => false
			)
		end
	end

	def down
		ss = ServiceSpace.where(:name => "Innovation Studio").first

		Resource.where(:service_space_id => ss.id).delete_all
	end
end