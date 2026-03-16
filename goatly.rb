cask "goatly" do
  version "0.1.0"
  sha256 "REPLACE_WITH_ACTUAL_SHA256" # Run `curl -L -o goatly-macos.zip https://github.com/JustinGuese/flutter-simple-meeting-recorder-transcriber-summarizer/releases/download/v#{version}/goatly-macos.zip && shasum -a 256 goatly-macos.zip`

  url "https://github.com/JustinGuese/flutter-simple-meeting-recorder-transcriber-summarizer/releases/download/v#{version}/goatly-macos.zip"
  name "GOATLY Meeting Summarizer"
  desc "AI-powered meeting recorder, transcriber, and summarizer"
  homepage "https://justinguese.github.io/flutter-simple-meeting-recorder-transcriber-summarizer/"

  app "goatly_meeting_transcriber_summarizer.app"

  zap trash: [
    "~/Library/Application Support/goatly_meeting_transcriber_summarizer",
    "~/Library/Preferences/com.example.goatlyMeetingTranscriberSummarizer.plist", # Replace with actual bundle ID if different
    "~/Library/Saved Application State/com.example.goatlyMeetingTranscriberSummarizer.savedState",
  ]
end
