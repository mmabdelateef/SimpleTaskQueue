Pod::Spec.new do |s|

  s.name         = "SimpleTaskQueue"
  s.version      = "1.0.2"
  s.summary      = "Execute tasks sequentially, one after the other. gurantee only one task is running at any time"

  s.description  = "A simple implementation for a queue to execute tasks sequentially, as simplest as possible. Execute tasks sequentially, one after the other. gurantee only one task is running at any time"

  s.homepage     = "https://github.com/mmabdelateef/SimpleTaskQueue"

  s.license      = "MIT"



  s.author             = { "mabdellateef" => "mmabdelateef@gmail.com" }
  s.social_media_url   = "https://twitter.com/mmabdellateef"

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/mmabdelateef/SimpleTaskQueue.git", :tag => "1.0.2" }

  s.source_files  = "SimpleTaskQueue", "SimpleTaskQueue/**/*.{h,m,swift}"
  s.swift_version = "4.1"

end
