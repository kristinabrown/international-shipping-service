class GoogleDriveService
  attr_reader :session

  def initialize
    @session = GoogleDrive::Session.from_config("config.json")
  end

  def upload_addresses(file_path)
    file = session.file_by_title(ENV['FILE_NAME'])
    file.export_to_io(file_path, 'text/csv')
  end
end
