require 'rails_helper'
require 'spec_helper'
require 'typed_parameters'

describe TypedParameters do

  # Quick and dirty mock controller context for a request
  def request(params, action = :create)
    OpenStruct.new(
      action_name: action,
      params: params,
      request: OpenStruct.new(
        raw_post: JSON.generate(params),
        format: Mime[:json]
      )
    )
  end

  context "type checks" do
    it "should allow requests that contain valid types" do
      params = lambda {
        ctx = request key: "value"

        TypedParameters.build ctx do
          on(:create) { param :key, type: :string }
        end
      }
      expect(params.call).to eq "key" => "value"
    end

    it "should disallow requests that contain a type mismatch" do
      params = lambda {
        ctx = request key: 1

        TypedParameters.build ctx do
          on(:create) { param :key, type: :string }
        end
      }
      expect(&params).to raise_error { |err|
        expect(err).to be_a TypedParameters::InvalidParameterError
        expect(err.source).to include pointer: "/key"
      }
    end

    it "should allow requests that contain a type mismatch that can be coerced" do
      params = lambda {
        ctx = request key: "1"

        TypedParameters.build ctx do
          on(:create) { param :key, type: :integer, coerce: true }
        end
      }
      expect(params.call).to eq "key" => 1
    end

    it "should disallow requests that contain a type mismatch that cannot be coerced" do
      params = lambda {
        ctx = request key: Object.new

        TypedParameters.build ctx do
          on(:create) { param :key, type: :integer, coerce: true }
        end
      }
      expect(&params).to raise_error { |err|
        expect(err).to be_a TypedParameters::InvalidParameterError
        expect(err.source).to include pointer: "/key"
      }
    end

    it "should allow requests that contain a hash with scalar values" do
      params = lambda {
        ctx = request hash: { key: "value" }

        TypedParameters.build ctx do
          on(:create) { param :hash, type: :hash }
        end
      }
      expect(params.call).to eq "hash" => { "key" => "value" }
    end

    it "should disallow requests that contain a hash with non-scalar values" do
      params = lambda {
        ctx = request hash: { nested: { key: "value" } }

        TypedParameters.build ctx do
          on(:create) { param :hash, type: :hash }
        end
      }
      expect(&params).to raise_error { |err|
        expect(err).to be_a TypedParameters::InvalidParameterError
        expect(err.source).to include pointer: "/hash"
      }
    end

    it "should allow requests that contain a nested hash" do
      params = lambda {
        ctx = request hash: { nested: { key: "value" } }

        TypedParameters.build ctx do
          on :create do
            param :hash, type: :hash do
              param :nested, type: :hash
            end
          end
        end
      }
      expect(params.call).to eq "hash" => { "nested" => { "key" => "value" } }
    end

    it "should disallow requests that contain a nested hash with missing keys" do
      params = lambda {
        ctx = request hash: { }

        TypedParameters.build ctx do
          on :create do
            param :hash, type: :hash do
              param :nested, type: :hash
            end
          end
        end
      }
      expect(&params).to raise_error { |err|
        expect(err).to be_a TypedParameters::InvalidParameterError
        expect(err.source).to include pointer: "/hash/nested"
      }
    end

    it "should allow requests that contain an array of scalar values" do
      params = lambda {
        ctx = request array: [1, 2, 3]

        TypedParameters.build ctx do
          on(:create) { param :array, type: :array }
        end
      }
      expect(params.call).to eq "array" => [1, 2, 3]
    end

    it "should disallow requests that contain an array of non-scalar values" do
      params = lambda {
        ctx = request array: [[1, 2], [3]]

        TypedParameters.build ctx do
          on(:create) { param :array, type: :array }
        end
      }
      expect(&params).to raise_error { |err|
        expect(err).to be_a TypedParameters::InvalidParameterError
        expect(err.source).to include pointer: "/array"
      }
    end

    it "should allow requests that contain an array of hashes" do
      params = lambda {
        ctx = request array: [{ key: "value" }, { key: "value" }]

        TypedParameters.build ctx do
          on :create do
            param :array, type: :array do
              items type: :hash do
                param :key, type: :string
              end
            end
          end
        end
      }
      expect(params.call).to eq "array" => [
        { "key" => "value" }, { "key" => "value" }
      ]
    end

    it "should disallow requests that contain an array of hashes with a type error" do
      params = lambda {
        ctx = request array: [{ key: true }, { key: 3 }]

        TypedParameters.build ctx do
          on :create do
            param :array, type: :array do
              items type: :hash do
                param :key, type: :string
              end
            end
          end
        end
      }
      expect(&params).to raise_error { |err|
        expect(err).to be_a TypedParameters::InvalidParameterError
        expect(err.source).to include pointer: "/array/key"
      }
    end
  end

  context "permits" do
    it "should allow requests that contain permitted keys" do
      params = lambda {
        ctx = request a: "value", b: 1

        TypedParameters.build ctx do
          on :create do
            param :a, type: :string
            param :b, type: :integer
          end
        end
      }
      expect(params.call).to eq "a" => "value", "b" => 1
    end

    it "should filter requests that contain unpermitted keys" do
      params = lambda {
        ctx = request a: "value", b: 1, c: false

        TypedParameters.build ctx do
          on :create do
            param :a, type: :string
            param :b, type: :integer
          end
        end
      }
      expect(params.call).to eq "a" => "value", "b" => 1
    end

    it "should disallow requests that contain unpermitted keys when in strict mode" do
      params = lambda {
        ctx = request a: "value", b: 1, c: false

        TypedParameters.build ctx do
          options strict: true

          on :create do
            param :a, type: :string
            param :b, type: :integer
          end
        end
      }
      expect(&params).to raise_error TypedParameters::UnpermittedParametersError
    end
  end

  context "validations" do
    # TODO: Write spec for param validations
  end

  context "transforms" do
    it "should transform a hash to a string value" do
      params = lambda {
        ctx = request key: { foo: "value" }

        TypedParameters.build ctx do
          options strict: true

          on :create do
            param :key, type: :hash, transform: -> (k, v) { [k, v[:foo]] }
          end
        end
      }
      expect(params.call).to eq "key" => "value"
    end

    it "should transform a string to a hash value" do
      params = lambda {
        ctx = request key: "value"

        TypedParameters.build ctx do
          options strict: true

          on :create do
            param :key, type: :string, transform: -> (k, v) { [k, { foo: v }] }
          end
        end
      }
      expect(params.call).to eq "key" => { "foo" => "value" }
    end

    it "should transform the param's key" do
      params = lambda {
        ctx = request key: "value"

        TypedParameters.build ctx do
          options strict: true

          on :create do
            param :key, type: :string, transform: -> (k, v) { ["#{k}_attributes", v] }
          end
        end
      }
      expect(params.call).to eq "key_attributes" => "value"
    end

    # TODO: Write additional specs for param transformations
  end
end
