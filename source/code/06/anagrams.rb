class Dictionary
  def initialize
    @words = {}
  end
  
  def add(word)
    (@words[signature(word)] ||= []) << word
  end
  
  def anagrams
    @words.each do |_key, words|
      yield(words) if words.size > 1
    end
  end

private
  def signature(word)
    word.unpack("c*").sort.pack("c*")
  end
end

dict = Dictionary.new

STDIN.each do |line|
  dict.add(line.chomp)
end

dict.anagrams do |words|
  puts words.join(" ")
end
  
