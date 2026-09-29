#!/usr/bin/env ruby
# Merges the Facebook / SKAdNetwork keys Apple reads from the host Info.plist.
# App ID, client token, and display name still come from SdkBootstrap at runtime.
# When FacebookAppID is already in the plist, the fb[APP_ID] URL scheme is added.

require 'open3'

PLIST_BUDDY = '/usr/libexec/PlistBuddy'
SKAD_IDS = %w[v9wttpbfk9.skadnetwork n38lu8286q.skadnetwork].freeze
TRACKING_USAGE = 'This identifier is used to measure which ads brought you to the app.'

pods_root = ENV['PODS_ROOT']
candidates = []
candidates << File.expand_path('../Runner/Info.plist', pods_root) if pods_root && !pods_root.empty?
candidates << File.expand_path('../../example/ios/Runner/Info.plist', __dir__)

plist = candidates.find { |path| File.file?(path) }
unless plist
  warn "[AllInOneSdk] Facebook Info.plist import skipped (Runner/Info.plist not found)"
  exit 0
end

def buddy(plist, command)
  stdout, _stderr, status = Open3.capture3(PLIST_BUDDY, '-c', command, plist)
  [status.success?, stdout.to_s.strip]
end

def missing?(plist, command)
  ok, = buddy(plist, command)
  !ok
end

changed = []

SKAD_IDS.each do |identifier|
  ok, printed = buddy(plist, 'Print :SKAdNetworkItems')
  existing = ok ? printed : ''
  next if existing.include?(identifier)

  if missing?(plist, 'Print :SKAdNetworkItems')
    buddy(plist, 'Add :SKAdNetworkItems array')
  end
  ok, count_out = buddy(plist, 'Print :SKAdNetworkItems')
  index = ok ? count_out.scan(/SKAdNetworkIdentifier/).length : 0
  buddy(plist, "Add :SKAdNetworkItems:#{index} dict")
  buddy(plist, "Add :SKAdNetworkItems:#{index}:SKAdNetworkIdentifier string #{identifier}")
  changed << identifier
end

if missing?(plist, 'Print :NSUserTrackingUsageDescription')
  buddy(plist, "Add :NSUserTrackingUsageDescription string #{TRACKING_USAGE}")
  changed << 'NSUserTrackingUsageDescription'
end

{
  'FacebookAdvertiserIDCollectionEnabled' => true,
  'FacebookAdvertiserTrackingEnabled' => true,
  'FacebookAutoLogAppEventsEnabled' => true,
}.each do |key, value|
  next unless missing?(plist, "Print :#{key}")

  buddy(plist, "Add :#{key} bool #{value}")
  changed << key
end

ok, app_id = buddy(plist, 'Print :FacebookAppID')
if ok && !app_id.empty? && app_id != '$(inherited)'
  scheme = "fb#{app_id}"
  ok, schemes = buddy(plist, 'Print :CFBundleURLTypes')
  schemes = '' unless ok
  unless schemes.include?(scheme)
    if missing?(plist, 'Print :CFBundleURLTypes')
      buddy(plist, 'Add :CFBundleURLTypes array')
    end
    ok, types = buddy(plist, 'Print :CFBundleURLTypes')
    index = ok ? types.scan(/Dict \{/).length : 0
    # PlistBuddy prints "Dict {" for each entry.
    index = types.scan(/cfbundleurlname|CFBundleURLSchemes/i).length if index.zero? && types.include?('Array')
    buddy(plist, "Add :CFBundleURLTypes:#{index} dict")
    buddy(plist, "Add :CFBundleURLTypes:#{index}:CFBundleURLSchemes array")
    buddy(plist, "Add :CFBundleURLTypes:#{index}:CFBundleURLSchemes:0 string #{scheme}")
    changed << scheme
  end
end

if changed.empty?
  puts "[AllInOneSdk] Facebook Info.plist already complete (#{plist})"
else
  puts "[AllInOneSdk] Facebook Info.plist imported: #{changed.join(', ')} (#{plist})"
end
