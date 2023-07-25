# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe 'keygen:permissions:add', type: :task do
  let(:account) { create(:account) }

  it 'should add permissions to provided licenses' do
    licenses = create_list(:license, 5,
      permissions: License.default_permissions - %w[package.read],
      account:,
    )

    run_task described_task, :license, licenses.first.id, licenses.third.id, 'package.read' do
      expect(licenses.first).to have_permissions 'package.read'
      expect(licenses.second).to_not have_permissions 'package.read'
      expect(licenses.third).to have_permissions 'package.read'
      expect(licenses.fourth).to_not have_permissions 'package.read'
      expect(licenses.fifth).to_not have_permissions 'package.read'
    end
  end

  it 'should append permissions to licenses with default permissions' do
    licenses = create_list(:license, 5,
      permissions: License.default_permissions - %w[package.read],
      account:,
    )

    run_task described_task, :license, *licenses.collect(&:id), 'package.read' do
      licenses.each do |license|
        expect(license).to have_permissions 'package.read', *License.default_permissions
      end
    end
  end

  it 'should not add permissions to licenses with custom permissions' do
    licenses = create_list(:license, 5,
      permissions: %w[license.validate license.read],
      account:,
    )

    run_task described_task, :license, *licenses.collect(&:id), 'machine.create' do
      licenses.each do |license|
        expect(license).to_not have_permissions 'machine.create'
      end
    end
  end

  it 'should not add permissions to licenses that are not allowed' do
    licenses = create_list(:license, 5,
      permissions: License.default_permissions,
      account:,
    )

    run_task described_task, :license, *licenses.collect(&:id), 'license.create' do
      licenses.each do |license|
        expect(license).to_not have_permissions 'license.create'
      end
    end
  end

  it 'should raise for model without role permissions' do
    tokens = create_list(:token, 5,
      permissions: License.default_permissions,
      account:,
    )

    expect { run_task described_task, :token, *tokens.collect(&:id), 'product.create' }
      .to raise_error ActiveRecord::AssociationNotFoundError
  end
end
