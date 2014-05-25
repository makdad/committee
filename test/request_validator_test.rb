require_relative "test_helper"

require "stringio"

describe Committee::RequestValidator do
  before do
    @schema =
      JsonSchema.parse!(MultiJson.decode(File.read("./test/data/schema.json")))
    @schema.expand_references!
    # POST /apps/:id
    @link = @link = @schema.properties["app"].links[0]
    @request = Rack::Request.new({
      "CONTENT_TYPE" => "application/json",
    })
  end

  it "passes through a valid request" do
    data = {
      "name" => "heroku-api",
    }
    call(data)
  end

  it "detects an invalid request Content-Type" do
    e = assert_raises(Committee::InvalidRequest) {
      @request =
        Rack::Request.new("CONTENT_TYPE" => "application/x-www-form-urlencoded")
      call({})
    }
    message =
      %{"Content-Type" request header must be set to "application/json".}
    assert_equal message, e.message
  end

  it "detects a parameter of the wrong pattern" do
    data = {
      "name" => "%@!"
    }
    e = assert_raises(Committee::InvalidRequest) do
      call(data)
    end
    message = %{Invalid request.\n\n#/name: failed schema #/definitions/app/links/0/schema/properties/name: Expected string to match pattern "/^[a-z][a-z0-9-]{3,30}$/", value was: %@!.}
    assert_equal message, e.message
  end

  private

  def call(data)
    Committee::RequestValidator.new(@link).call(@request, data)
  end
end
