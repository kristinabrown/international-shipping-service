class GoogleDriveService
  attr_reader :session

  def initialize
    @session = GoogleDrive::Session.from_config("config.json")
  end

  def upload_addresses(io)
    file = session.file_by_title(ENV['FILE_NAME'])
    file.update_from_io(io)
  end
end
