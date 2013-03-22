# The etymology of this class name is that I needed a base class
# that describes managers of ruby environments.  Given that RVM
# and rbenv were already taken, I went with a self-deprecating
# variation on manager.

class Clerk

protected

  # compare source releases by patch number
  RELEASE_COMPARE = Proc.new do |a,b|
    pattern = /(.*?)(\d+)$/
    if a =~ pattern and a[pattern,1] == b[pattern,1]
      a[pattern,2].to_i <=> b[pattern,2].to_i
    else
      a <=> b
    end
  end
end
