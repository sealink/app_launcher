AppLauncher::Application.routes.draw do
  root :to => 'apps#index'

  match 'apps/start/:id'  => 'apps#start',    via: %i(get post)
  match 'apps/stop/:id'   => 'apps#stop',     via: %i(get post)
  match 'apps/status/:id' => 'apps#status',   via: %i(get post)

  match 'apps/:id/show'   => 'apps#show_app', via: %i(get post)
end
