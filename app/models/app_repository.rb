class AppRepository
  attr_reader :apps_config

  def self.all
    new.all
  end

  def self.find_by_id(id)
    new.find_by_id(id)
  end

  def initialize
    @config_file = "#{Rails.root}/config/apps.yml"
  end

  def all
    @all ||= apps_config.map { |app_id, config| configure_app(app_id, config) }
  end

  def find_by_id(id)
    all.detect { |app| app.id == id }
  end

  def apps_config
    YAML::load_file(@config_file)
  end

  # OLD FORMAT:
  # Each app included multiple apps, some were services, some user-facing apps:
  # 'kis-next-qt':
  #   name: 'KIS Next QT'
  #   unicorn: 'https://kis-next-qt.quicktravel.com.au'
  #   cms: 'http://kis-next-cms.quicktravel.com.au'
  #   adss: 'http://adss1.quicktravel.com.au'
  #   color: '#ccf'
  #
  # The code is defective, ignoring these totally, EXCEPT for unicorn & cms
  # ...and has to treat special cases everywhere due to 'cms' being a user
  # facing app with it's own id.
  #
  # NEW FORMAT:
  # Each app is one user-facing app, and contains only information & services
  #
  # 'kis-next-qt':
  #   name: 'KIS Next QUICKTRAVEL'
  #   color: '#ccf'
  #   url: 'https://kis-next-qt.quicktravel.com.au'
  #   services:
  #     - index: solr
  #   - workers: resque-pool
  #   - scheduled-jobs: schedule
  #   - quicktravel: unicorn
  #
  # 'kis-next-cms':
  #   name: 'KIS Next SEALINK WEBSITE'
  #   url: 'http://kis-next-cms.quicktravel.com.au'
  #   color: '#ccf'
  #   services:
  #     - sealink-cms: unicorn
  def configure_app(id, raw_config)
    config = raw_config.symbolize_keys

    app = App.new(id, config.slice(:name, :url, :color))
    config.fetch(:services, []).each do |service_id, service_type|
      app.add_service(service_id, service_type)
    end
    app
  end
end
