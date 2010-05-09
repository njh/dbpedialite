$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))

def fixture(filename)
  File.join(File.dirname(__FILE__),'fixtures',filename)
end
