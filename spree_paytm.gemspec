Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_paytm'
  s.version     = '1.0'
  s.summary     = 'Spree integration with Paytm.'
  s.description = 'Spree integration with Paytm.'

  s.author    = 'Santosh Singh'
  s.email     = 'santosh.singh@freshmonk.com'
  s.homepage  = 'https://github.com/isantoshsingh/spree_paytm'

  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '~> 3.0'
end