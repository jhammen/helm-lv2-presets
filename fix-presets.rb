require 'base64'

manifest_ttl = "/usr/lib/lv2/helm.lv2/manifest.ttl"
presets_ttl = "/usr/lib/lv2/helm.lv2/presets.ttl"
presets_dir = "../helm/patches"

preset_regex = /<http\:\/\/tytel.org\/helm\#preset(\d+)\>/

# grab and hash correct .helm presets
configs = Hash.new
Dir[ File.join(presets_dir, '**', '*') ]
  .reject { |p| File.directory? p }.each do|f|
  if(f =~ /([^\/]+)\.helm/)
    configs[$1.downcase] = File.read(f).strip + "\0"
  end
end

# map numbers to names
name = Hash.new
File.open(manifest_ttl, 'r') do |file|
  current = 0
  file.each_line do |line|
    if line =~ preset_regex
      current = $1
    elsif line =~ /rdfs:label "([^\"]+)"/
      name[current] = $1.downcase
    end
  end
end

# inject correct presets into presets.ttl
begin
  File.open(presets_ttl, 'r') do |file|
    current = 0
    file.each_line do |line|
      if line =~ preset_regex
        current = $1
      elsif line =~ /rdf:value \"([^\"]+)\"/
        old_string = $1
        config = Base64.decode64(old_string)
        new_config = configs[name[current]]
        if new_config
          new_string = Base64.strict_encode64(new_config)
          line.gsub!(old_string, new_string)
        end
      end
      puts line
    end
  end
end

