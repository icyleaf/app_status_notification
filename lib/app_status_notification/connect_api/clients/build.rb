# frozen_string_literal: true

module AppStatusNotification
  class ConnectAPI
    module Client
      module Build
        def app_latest_build(id)
          app_builds(id, limit: 1).to_model
        end

        def app_builds(id, **kargs)
          kargs = kargs.merge(filter: { app: id })
          builds(**kargs)
        end

        def builds(limit: 200, sort: '-uploadedDate',
          includes: ConnectAPI::Model::Build::ESSENTIAL_INCLUDES,
                   **kargs)

          kargs = kargs.merge(limit: limit)
            .merge(sort: sort)
            .merge(include: includes)

          get('builds', **kargs)
        end
      end
    end
  end
end
