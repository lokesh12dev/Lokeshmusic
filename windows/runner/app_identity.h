#ifndef RUNNER_APP_IDENTITY_H_
#define RUNNER_APP_IDENTITY_H_

// Identify Lokeshmusic consistently in the Windows shell.
inline constexpr wchar_t kLokeshmusicAppId[] = L"com.lokesh.lokeshmusic";

// Register the shell identity before creating any windows.
void ConfigureAppIdentity();

#endif  // RUNNER_APP_IDENTITY_H_
