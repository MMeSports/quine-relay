# usage:
#   ruby test.rb      # test all Steps
#   ruby test.rb Perl # test only Perl Step

require_relative "code-gen"

ENV["PATH"] = "vendor/local/bin:#{ ENV["PATH"] }"

dir = File.join(File.dirname(__dir__), "tmp")
Dir.mkdir(dir) unless File.directory?(dir)
Dir.chdir(dir)
File.symlink("../vendor", "vendor") unless File.symlink?("vendor")

gens = ARGV[0] ? [eval(ARGV[0])] : GenSteps[0..-2]
text = ARGV[1] || "Hello"

all_check = true

gens.each do |gen_step|
  puts "test: %s" % gen_step.name

  code = Object.new.instance_eval(GenPrologue + gen_step.code.sub("PREV") { text.dump }) + "\n"
  code.sub!("%%", "%") if gen_step.name == "Octave_Ook"

  steps = [*gen_step.run_steps, RunStep[nil, "QR.txt"]]

  File.write(steps.first.src, code)

  steps.each_cons(2) do |src, dst|
    cmd = src.cmd.gsub("OUTFILE", dst.src)
    cmd = cmd.gsub(/mv QR\.c QR\.c\.bak &&|&& mv QR\.c\.bak QR\.c/, "")
    cmd = cmd.gsub(/mv QR\.bc QR\.bc\.bak &&|&& mv QR\.bc\.bak QR\.bc/, "")
    cmd = cmd.gsub("$(SCHEME)", "gosh")
    cmd = cmd.gsub("$(JAVASCRIPT)", "rhino")
    cmd = cmd.gsub("$(BF)", "bf")
    cmd = cmd.gsub("$(CC)", "gcc")
    cmd = cmd.gsub("$(CXX)", "g++")
    cmd = cmd.gsub("$(GBS)", "gbs3")
    puts "cmd: " + cmd
    system(cmd) || raise("failed")
  end

  check = File.read("QR.txt").strip == text
  all_check &&= check
  puts "result: #{ check ? "OK" : "NG" }"
  puts
end

puts all_check ? "all ok" : "something wrong"
