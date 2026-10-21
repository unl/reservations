# Helpers for lists of half-open time intervals [start, end) given in epoch
# seconds. An end of Float::INFINITY means "open-ended" (e.g. a lockout that
# has not been released); clip such lists before measuring them.
module Intervals
  extend self

  # Sorted, non-overlapping union of the list.
  def union(list)
    list.select { |s, e| s < e }.sort.each_with_object([]) do |(s, e), merged|
      if !merged.empty? && s <= merged.last[1]
        merged.last[1] = e if e > merged.last[1]
      else
        merged << [s, e]
      end
    end
  end

  def intersect(a, b)
    a = union(a)
    b = union(b)
    result = []
    i = j = 0
    while i < a.length && j < b.length
      s = [a[i][0], b[j][0]].max
      e = [a[i][1], b[j][1]].min
      result << [s, e] if s < e
      if a[i][1] < b[j][1]
        i += 1
      else
        j += 1
      end
    end
    result
  end

  # Parts of `a` not covered by `b`.
  def subtract(a, b)
    b = union(b)
    union(a).flat_map do |s, e|
      pieces = []
      b.each do |bs, be|
        next if be <= s || bs >= e

        pieces << [s, bs] if bs > s
        s = be
      end
      pieces << [s, e] if s < e
      pieces
    end
  end

  def clip(list, from, to)
    intersect(list, [[from, to]])
  end

  # Total length in seconds (overlaps are counted twice; union first if needed).
  def seconds(list)
    list.sum { |s, e| e - s }
  end
end
