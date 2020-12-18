# frozen_string_literal: true

module AppStatusNotification
  class ConnectAPI
    module Client
      module AppStoreVersion
        def versions(query = {})
          get('appStoreVersions', query)
        end

        def version(id, query = {})
          get("appStoreVersions/#{id}", query)
        end

        def select_version_build(id, build_id:)
          body = {
            data: {
              type: 'builds',
              id: build_id
            }
          }

          patch("appStoreVersions/#{id}/relationships/build", body: body)
        end
      end
    end
  end
end
