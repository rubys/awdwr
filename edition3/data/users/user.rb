require 'digest/sha1'

#START:validate
class User < ActiveRecord::Base
  
  validates_presence_of     :name
  validates_uniqueness_of   :name
 
  attr_accessor :password_confirmation
  validates_confirmation_of :password

  validate :password_non_blank
  
#END:validate
  #START:login
  def self.authenticate(name, password)
    user = self.find_by_name(name)
    if user
      expected_password = encrypted_password(password, user.salt)
      if user.hashed_password != expected_password
        user = nil
      end
    end
    user
  end
  #END:login
  
  # 'password' is a virtual attribute
  #START:accessors
  def password
    @password
  end
  
  def password=(pwd)
    @password = pwd
    return if pwd.blank?
    create_new_salt
    self.hashed_password = User.encrypted_password(self.password, self.salt)
  end
  #END:accessors
  
#START:validate
private

  def password_non_blank
    errors.add(:password, "Missing password") if hashed_password.blank?
  end
#END:validate
  
  #START:create_new_salt
  def create_new_salt
    self.salt = self.object_id.to_s + rand.to_s
  end
  #END:create_new_salt
  
  #START:encrypted_password
  def self.encrypted_password(password, salt)
    string_to_hash = password + "wibble" + salt
    Digest::SHA1.hexdigest(string_to_hash)
  end
  #END:encrypted_password
#START:validate  
end
#END:validate
