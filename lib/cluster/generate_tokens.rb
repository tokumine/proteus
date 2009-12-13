tokens = {}

pas = Pa.find_each( :select => 'DISTINCT name_eng, gid', :batch_size => 100 ) do |p|
  p.name_eng.split(/\W/).each do |t|
    tokens[t] ||=0
    tokens[t] += 1
  end
end
sorted_tokens = tokens.sort {|a,b| b[1]<=>a[1]}

puts sorted_tokens.inspect