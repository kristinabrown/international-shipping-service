class GoogleDriveService
  attr_reader :session

  def initialize
    @session = GoogleDrive::Session.from_service_account_key(StringIO.new(ENV['GOOGLE_CLIENT_SECRETS']))
  end

  def upload_addresses(io)
    file = session.file_by_title(ENV['FILE_NAME'])
    file.update_from_io(io)
  end
end
