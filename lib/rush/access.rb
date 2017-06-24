# A class to hold permissions (read, write, execute) for files and dirs.
# See Rush::Entry#access= for information on the public-facing interface.
#
class Rush::Access
  ROLES = %w(user group other)
  PERMISSIONS = %w(read write execute)
  ACCESS_UNITS = ROLES.product(PERMISSIONS).
    map { |r, p| "#{r}_can_#{p}".to_sym }

  attr_accessor *ACCESS_UNITS

  def self.roles
    ROLES
  end

  def self.permissions
    PERMISSIONS
  end

  def parse(options)
    options.each do |key, value|
      next unless m = key.to_s.match(/(.*)_can$/)
      key = m[1].to_sym
      roles = extract_list('role', key, self.class.roles)
      perms = extract_list('permission', value, self.class.permissions)
      set_matrix(perms, roles)
    end
    self
  end

  def self.parse(options)
    new.parse(options)
  end

  def apply(full_path)
    FileUtils.chmod(octal_permissions, full_path)
  rescue Errno::ENOENT
    raise Rush::DoesNotExist, full_path
  end

  def to_hash
    ACCESS_UNITS.inject({}) do |hash, unit|
      hash.merge(unit => send(unit) ? 1 : 0)
    end
  end

  def display_hash
    to_hash.select { |_, v| v == 1 }.
      inject({}) { |r, (k, _)| r.merge k => true }
  end

  def from_hash(hash)
    ACCESS_UNITS.each do |unit|
      send("#{unit}=".to_sym, hash[unit].to_i == 1 ? true : false)
    end
    self
  end

  def self.from_hash(hash)
    new.from_hash(hash)
  end

  def octal_permissions
    perms = [ 0, 0, 0 ]
    perms[0] += 4 if user_can_read
    perms[0] += 2 if user_can_write
    perms[0] += 1 if user_can_execute

    perms[1] += 4 if group_can_read
    perms[1] += 2 if group_can_write
    perms[1] += 1 if group_can_execute

    perms[2] += 4 if other_can_read
    perms[2] += 2 if other_can_write
    perms[2] += 1 if other_can_execute

    eval("0" + perms.join)
  end

  def from_octal(mode)
    perms = octal_integer_array(mode)

    self.user_can_read = (perms[0] & 4) > 0 ? true : false
    self.user_can_write = (perms[0] & 2) > 0 ? true : false
    self.user_can_execute = (perms[0] & 1) > 0 ? true : false

    self.group_can_read = (perms[1] & 4) > 0 ? true : false
    self.group_can_write = (perms[1] & 2) > 0 ? true : false
    self.group_can_execute = (perms[1] & 1) > 0 ? true : false

    self.other_can_read = (perms[2] & 4) > 0 ? true : false
    self.other_can_write = (perms[2] & 2) > 0 ? true : false
    self.other_can_execute = (perms[2] & 1) > 0 ? true : false

    self
  end

  def octal_integer_array(mode)
    mode %= 01000                      # filter out everything but the bottom three digits
    mode = sprintf("%o", mode)         # convert to string
    mode.split("").map { |p| p.to_i }  # and finally, array of integers
  end

  def set_matrix(perms, roles)
    ROLES.product(PERMISSIONS).
      select { |r, p| perms.include?(p) && roles.include?(r) }.
      map    { |r, p| "#{r}_can_#{p}=".to_sym }.
      each   { |unit| send unit, true }
  end

  def extract_list(type, value, choices)
    list = parts_from(value)
    list.each do |value|
      raise(Rush::BadAccessSpecifier, "Unrecognized #{type}: #{value}") unless choices.include? value
    end
  end

  def parts_from(value)
    value.to_s.split('_').reject { |r| r == 'and' }
  end
end
