class GoogleDriveService
  attr_reader :session

  def initialize
    @session = GoogleDrive::Session.from_config("config.json")
  end

  def upload_addresses(file_path)
    file = session.file_by_title("Scotts Coffee Books")

    file.update_from_file(file_path)
  end
end
