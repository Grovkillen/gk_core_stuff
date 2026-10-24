# frozen_string_literal: true

# export_log: a print asked for in the browser
post 'gk_core_stuff/printed', to: 'gk_core_stuff_prints#create', as: 'gk_core_stuff_printed'
