class GoogleDriveService
  attr_reader :session

  def initialize
    default_scope = [
      "https://www.googleapis.com/auth/drive",
      "https://spreadsheets.google.com/feeds/"
    ]
    credentials = Google::Auth::UserRefreshCredentials.new(
            client_id: ENV['CLIENT_ID'],
            client_secret: ENV['CLIENT_SECRET'],
            scope: default_scope,
            redirect_uri: 'urn:ietf:wg:oauth:2.0:oob'
          )

    credentials.refresh_token = ENV['REFRESH_TOKEN']
    credentials.fetch_access_token!
    @session = GoogleDrive::Session.new(credentials)
  end

  def upload_addresses(io)
    file = session.file_by_title(ENV['FILE_NAME'])
    file.update_from_io(io)
  end
end
