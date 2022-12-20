# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root.join('lib', 'keygen')

describe Keygen, type: :ee do
  describe '.console?' do
    within_console do
      it 'should return true in a console env' do
        expect(Keygen.console?).to be true
      end
    end

    within_worker do
      it 'should return false in a worker env' do
        expect(Keygen.console?).to be false
      end
    end

    within_server do
      it 'should return false in a server env' do
        expect(Keygen.console?).to be false
      end
    end

    it 'should return false in another env' do
      expect(Keygen.console?).to be false
    end
  end

  describe '.server?' do
    within_console do
      it 'should return false in a console env' do
        expect(Keygen.server?).to be false
      end
    end

    within_worker do
      it 'should return false in a worker env' do
        expect(Keygen.server?).to be false
      end
    end

    within_server do
      it 'should return true in a server env' do
        expect(Keygen.server?).to be true
      end
    end

    it 'should return false in another env' do
      expect(Keygen.server?).to be false
    end
  end

  describe '.worker?' do
    within_console do
      it 'should return false in a console env' do
        expect(Keygen.worker?).to be false
      end
    end

    within_worker do
      it 'should return true in a worker env' do
        expect(Keygen.worker?).to be true
      end
    end

    within_server do
      it 'should return false in a server env' do
        expect(Keygen.worker?).to be false
      end
    end

    it 'should return false in another env' do
      expect(Keygen.worker?).to be false
    end
  end

  describe '.ce?' do
    within_ce do
      it 'should return true in a CE env' do
        expect(Keygen.ce?).to be true
      end
    end

    within_ee do
      it 'should return false in an EE env' do
        expect(Keygen.ce?).to be false
      end
    end
  end

  describe '.ee?' do
    within_ce do
      it 'should return false in a CE env' do
        expect(Keygen.ee?).to be false
      end
    end

    within_ee do
      it 'should return true in an EE env' do
        expect(Keygen.ee?).to be true
      end
    end
  end

  describe '.ee' do
    within_ce do
      it 'should not call the block in a CE env' do
        expect(Keygen.ee { 1 }).to be nil
      end
    end

    within_ee do
      it 'should call the block in an EE env' do
        expect(Keygen.ee { 1 }).to be 1
      end
    end
  end
end
