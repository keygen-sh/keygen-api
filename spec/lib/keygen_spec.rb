# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'keygen'

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

    within_task do
      it 'should return false in a task env' do
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

    within_task do
      it 'should return false in a task env' do
        expect(Keygen.server?).to be false
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

    within_task do
      it 'should return false in a task env' do
        expect(Keygen.worker?).to be false
      end
    end

    it 'should return false in another env' do
      expect(Keygen.worker?).to be false
    end
  end

  describe '.task?' do
    within_console do
      it 'should return false in a console env' do
        expect(Keygen.task?).to be false
      end
    end

    within_worker do
      it 'should return true in a worker env' do
        expect(Keygen.task?).to be false
      end
    end

    within_server do
      it 'should return false in a server env' do
        expect(Keygen.task?).to be false
      end
    end

    within_task do
      it 'should return true in a task env' do
        expect(Keygen.task?).to be true
      end
    end

    it 'should return false in another env' do
      expect(Keygen.task?).to be false
    end
  end

  describe '.multiplayer?' do
    within_ce do
      with_env KEYGEN_MODE: 'multiplayer' do
        it 'should return true in lax multiplayer mode' do
          expect(Keygen.multiplayer?(strict: false)).to be true
        end
      end

      with_env KEYGEN_MODE: 'multiplayer' do
        it 'should return false in multiplayer mode' do
          expect(Keygen.multiplayer?).to be false
        end
      end

      with_env KEYGEN_MODE: 'singleplayer' do
        it 'should return false in singleplayer mode' do
          expect(Keygen.multiplayer?).to be false
        end
      end

      with_env KEYGEN_MODE: nil do
        it 'should return false in nil mode' do
          expect(Keygen.multiplayer?).to be false
        end
      end
    end

    within_ee do
      with_env KEYGEN_MODE: 'multiplayer' do
        it 'should return true in lax multiplayer mode' do
          expect(Keygen.multiplayer?(strict: false)).to be true
        end
      end

      with_env KEYGEN_MODE: 'multiplayer' do
        it 'should return true in multiplayer mode' do
          expect(Keygen.multiplayer?).to be true
        end
      end

      with_env KEYGEN_MODE: 'singleplayer' do
        it 'should return false in singleplayer mode' do
          expect(Keygen.multiplayer?).to be false
        end
      end

      with_env KEYGEN_MODE: nil do
        it 'should return false in nil mode' do
          expect(Keygen.multiplayer?).to be false
        end
      end
    end
  end

  describe '.singleplayer?' do
    within_ce do
      with_env KEYGEN_MODE: 'multiplayer' do
        it 'should return false in lax multiplayer mode' do
          expect(Keygen.singleplayer?(strict: false)).to be false
        end
      end

      with_env KEYGEN_MODE: 'multiplayer' do
        it 'should return true in multiplayer mode' do
          expect(Keygen.singleplayer?).to be true
        end
      end

      with_env KEYGEN_MODE: 'singleplayer' do
        it 'should return true in singleplayer mode' do
          expect(Keygen.singleplayer?).to be true
        end
      end

      with_env KEYGEN_MODE: nil do
        it 'should return true in nil mode' do
          expect(Keygen.singleplayer?).to be true
        end
      end
    end

    within_ee do
      with_env KEYGEN_MODE: 'multiplayer' do
        it 'should return false in lax multiplayer mode' do
          expect(Keygen.singleplayer?(strict: false)).to be false
        end
      end

      with_env KEYGEN_MODE: 'multiplayer' do
        it 'should return false in multiplayer mode' do
          expect(Keygen.singleplayer?).to be false
        end
      end

      with_env KEYGEN_MODE: 'singleplayer' do
        it 'should return true in singleplayer mode' do
          expect(Keygen.singleplayer?).to be true
        end
      end

      with_env KEYGEN_MODE: nil do
        it 'should return true in nil mode' do
          expect(Keygen.singleplayer?).to be true
        end
      end
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

    with_env KEYGEN_EDITION: nil do
      it 'should return true with nil edition' do
        expect(Keygen.ce?).to be true
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

    with_env KEYGEN_EDITION: nil do
      it 'should return false with nil edition' do
        expect(Keygen.ee?).to be false
      end
    end
  end

  describe '.cloud?' do
    within_ce do
      with_env KEYGEN_MODE: 'singleplayer', KEYGEN_HOST: 'api.acme.example' do
        it 'should return false in a CE env' do
          expect(Keygen.cloud?).to be false
        end
      end

      with_env KEYGEN_MODE: 'singleplayer', KEYGEN_HOST: 'api.keygen.sh' do
        it 'should return false in a CE env' do
          expect(Keygen.cloud?).to be false
        end
      end

      with_env KEYGEN_MODE: 'multiplayer', KEYGEN_HOST: 'api.acme.example' do
        it 'should return false in a CE env' do
          expect(Keygen.cloud?).to be false
        end
      end

      with_env KEYGEN_MODE: 'multiplayer', KEYGEN_HOST: 'api.keygen.sh' do
        it 'should return false in a CE env' do
          expect(Keygen.cloud?).to be false
        end
      end
    end

    within_ee do
      with_env KEYGEN_MODE: 'singleplayer', KEYGEN_HOST: 'api.acme.example' do
        it 'should return false in an EE env' do
          expect(Keygen.cloud?).to be false
        end
      end

      with_env KEYGEN_MODE: 'singleplayer', KEYGEN_HOST: 'api.keygen.sh' do
        it 'should return false in an EE env' do
          expect(Keygen.cloud?).to be false
        end
      end

      with_env KEYGEN_MODE: 'multiplayer', KEYGEN_HOST: 'api.acme.example' do
        it 'should return false in an EE env' do
          expect(Keygen.cloud?).to be false
        end
      end

      with_env KEYGEN_MODE: 'multiplayer', KEYGEN_HOST: 'api.keygen.sh' do
        it 'should return true in an EE env' do
          expect(Keygen.cloud?).to be true
        end
      end
    end

    with_env KEYGEN_EDITION: nil do
      with_env KEYGEN_MODE: 'singleplayer', KEYGEN_HOST: 'api.acme.example' do
        it 'should return false with a nil edition' do
          expect(Keygen.cloud?).to be false
        end
      end

      with_env KEYGEN_MODE: 'singleplayer', KEYGEN_HOST: 'api.keygen.sh' do
        it 'should return false with nil edition' do
          expect(Keygen.cloud?).to be false
        end
      end

      with_env KEYGEN_MODE: 'multiplayer', KEYGEN_HOST: 'api.acme.example' do
        it 'should return false with a nil edition' do
          expect(Keygen.cloud?).to be false
        end
      end

      with_env KEYGEN_MODE: 'multiplayer', KEYGEN_HOST: 'api.keygen.sh' do
        it 'should return false with a nil edition' do
          expect(Keygen.cloud?).to be false
        end
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
