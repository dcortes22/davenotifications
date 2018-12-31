require "net/http"
require "uri"
require "json"
require "openssl"

class EventController < ApplicationController
    skip_before_action :verify_authenticity_token

    def payload
        event_type = params[:eventKey]
        author = params[:actor][:displayName]
        user = params[:actor][:name]
        email = params[:actor][:emailAddress]
        title = params[:pullRequest][:title]
        id = params[:pullRequest][:id]
        date = params[:date]
        createdDate = params[:pullRequest][:createdDate]
        link = "https://git.source.akamai.com/projects/MEDIADEV/repos/amp-ios-sdk-samples/pull-requests/#{params[:pullRequest][:id]}/overview"
        comment = params[:comment][:text] if params.key?("comment")

        object = {
            id: id,
            event_type: pr_type_name(event_type),
            author: author,
            user: user,
            email: email,
            title: title,
            date: date,
            createdDate: createdDate,
            link: link,
            comment: comment
        }
        if event_type.include? "pr"
            send_message(object)
        end
    end

    def pr_type_name(event_type)
        if event_type == "pr:opened"
            "Created a"
        elsif event_type == "pr:modified" 
            "Modified the"
        elsif event_type == "pr:reviewer:updated"
            "Updated the"
        elsif event_type == "pr:reviewer:approved"
            "Approved the"
        elsif event_type == "pr:reviewer:unapproved"
            "Unapproved the"
        elsif event_type == "pr:comment:added"
            "Added a Comment in the"
        end
    end

    def send_message(object)
        uri = URI("https://hooks.slack.com/services/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")
        params = {
            "attachments":[
                {
                    "fallback": "#{object[:author]} #{object[:event_type]} Pull Request",
                    "color": "#ff9933",
                    "pretext": "New Event on your Repository",
                    "author_name": "#{object[:author]}",
                    "author_link": "https://git.source.akamai.com/users/#{object[:user]}",
                    "title": "##{object[:id]} #{object[:title]}",
                    "title_link": "https://git.source.akamai.com/projects/MEDIADEV/repos/amp-ios-sdk-samples/pull-requests/#{object[:id]}/overview",
                    "text": "#{object[:author]} #{object[:event_type]} Pull Request",
                    "footer": "Akamai Stash Notifications",
                    "footer_icon": "https://www.akamai.com/us/en/multimedia/documents/media-resources/akamai-logo.jpg",
                    "ts": Time.now.to_i
                }
            ]
        }

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        response = http.post(uri.path, params.to_json)

        if( response.is_a?( Net::HTTPSuccess ) )
            # your request was successful
            respond_to do |format|
                format.json do
                  render json: :ok
                end
            end
          else
            # your request failed
            respond_to do |format|
                format.json do
                  render json: response.body
                end
            end
          end
        
        

    end
end
