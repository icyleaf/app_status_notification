# frozen_string_literal: true

module AppStatusNotification
  class ConnectAPI
    module Client
      module App
        def apps(query = {})
          get("apps", query = {})
        end

        def app(id, query = {})
          get("apps/#{id}", query).to_model
        end

        def app_versions(id, query = {})
          get("apps/#{id}/appStoreVersions", query)
        end

        def app_edit_version(id, includes: ConnectAPI::Model::AppStoreVersion::ESSENTIAL_INCLUDES)
          filters = {
            appStoreState: [
              ConnectAPI::Model::AppStoreVersion::AppStoreState::PREPARE_FOR_SUBMISSION,
              ConnectAPI::Model::AppStoreVersion::AppStoreState::DEVELOPER_REJECTED,
              ConnectAPI::Model::AppStoreVersion::AppStoreState::REJECTED,
              ConnectAPI::Model::AppStoreVersion::AppStoreState::METADATA_REJECTED,
              ConnectAPI::Model::AppStoreVersion::AppStoreState::WAITING_FOR_REVIEW,
              ConnectAPI::Model::AppStoreVersion::AppStoreState::INVALID_BINARY,
              ConnectAPI::Model::AppStoreVersion::AppStoreState::IN_REVIEW,
              ConnectAPI::Model::AppStoreVersion::AppStoreState::PENDING_DEVELOPER_RELEASE
            ].join(',')
          }

          app_versions(id, include: includes, filter: filters).to_model
        end

        def app_live_version(id, includes: ConnectAPI::Model::AppStoreVersion::ESSENTIAL_INCLUDES)
          filters = {
            appStoreState: ConnectAPI::Model::AppStoreVersion::AppStoreState::READY_FOR_SALE
          }

          app_versions(id, include: includes, filter: filters).to_model
        end
      end
    end
  end
end
