Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, "1840177282876343", "f74dd4f6a5108b3f75128f4d90a3211b"
end