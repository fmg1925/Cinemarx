Rails.application.config.session_store :active_record_store,
  key: "cinemarx_session",
  expire_after: 30.days
