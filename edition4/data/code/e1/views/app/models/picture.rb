class Picture < ActiveRecord::Base

  validates_format_of :content_type, 
                      with: /\Aimage/,
                      message: "must be a picture"

  def uploaded_picture=(picture_field)
    self.name         = base_part_of(picture_field.original_filename)
    self.content_type = picture_field.content_type.chomp
    self.data         = picture_field.read
  end

  def base_part_of(file_name)
    File.basename(file_name).gsub(/[^\w._-]/, '')
  end
end
