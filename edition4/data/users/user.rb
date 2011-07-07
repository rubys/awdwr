require 'digest/sha2'

#START:validate
class User < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true
 
  validates :password, :confirmation => true
  attr_accessor :password_confirmation
  attr_reader   :password

  validate  :password_must_be_present
  
#END:validate
  #START:login
  def User.authenticate(name, password)
    if user = find_by_name(name)
      if user.hashed_password == encrypt_password(password, user.salt)
        user
      end
    end
  end
  #END:login

  #START:encrypted_password
  def User.encrypt_password(password, salt)
    Digest::SHA2.hexdigest(password + "wibble" + salt)
  end
  #END:encrypted_password
  
  # 'password' is a virtual attribute
  #START:accessors
  def password=(password)
    @password = password

    if password.present?
      generate_salt
      self.hashed_password = self.class.encrypt_password(password, salt)
    end
  end
  #END:accessors
  
#START:validate
  private

    def password_must_be_present
      errors.add(:password, "Missing password") unless hashed_password.present?
    end
#END:validate
  
#START:create_new_salt
    def generate_salt
      self.salt = self.object_id.to_s + rand.to_s
    end
#END:create_new_salt
#START:validate  
end
#END:validate
