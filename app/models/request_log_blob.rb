class RequestLogBlob < ApplicationRecord
  enum blob_type: {
    request_headers:  :request_headers,
    request_body:     :request_body,
    response_headers: :response_headers,
    response_body:    :response_body,
    response_sig:     :response_signature,
  }

  belongs_to :request_log
end
