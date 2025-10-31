# frozen_string_literal: true

require_relative '../lib/sensitive_string'

RSpec.describe SensitiveString do
  describe '#to_s' do
    it 'returns a SHA256 hash instead of plaintext' do
      secret = SensitiveString.new('my-secret')
      result = secret.to_s

      expect(result).to start_with('sha256:')
      expect(result).not_to include('my-secret')
      expect(result.length).to eq(71) # "sha256:" (7) + 64 hex chars
    end

    it 'returns consistent hash for same value' do
      secret1 = SensitiveString.new('consistent')
      secret2 = SensitiveString.new('consistent')

      expect(secret1.to_s).to eq(secret2.to_s)
    end
  end

  describe '#inspect' do
    it 'returns debug representation with hash' do
      secret = SensitiveString.new('my-secret')
      result = secret.inspect

      expect(result).to match(/^#<SensitiveString:\d+ sha256:/)
      expect(result).not_to include('my-secret')
    end
  end

  describe '#value' do
    it 'returns the plaintext value' do
      secret = SensitiveString.new('my-secret')
      expect(secret.value).to eq('my-secret')
    end
  end

  describe '#to_json' do
    it 'serializes as hash instead of plaintext' do
      secret = SensitiveString.new('secret123')
      json = secret.to_json

      expect(json).to include('sha256:')
      expect(json).not_to include('secret123')
    end

    it 'works in a hash' do
      data = { password: SensitiveString.new('secret') }
      json = JSON.generate(data)

      expect(json).to include('sha256:')
      expect(json).not_to include('secret')
    end
  end

  describe '#as_json' do
    it 'returns hash for Rails serialization' do
      secret = SensitiveString.new('secret123')
      result = secret.as_json

      expect(result).to start_with('sha256:')
      expect(result).not_to include('secret123')
    end
  end

  describe '#==' do
    it 'compares by plaintext value' do
      secret1 = SensitiveString.new('same')
      secret2 = SensitiveString.new('same')
      secret3 = SensitiveString.new('different')

      expect(secret1).to eq(secret2)
      expect(secret1).not_to eq(secret3)
      expect(secret1).not_to eq('same') # Not equal to plain string
    end
  end

  describe '#hash' do
    it 'can be used as hash key' do
      secret1 = SensitiveString.new('key1')
      secret2 = SensitiveString.new('key2')
      secret3 = SensitiveString.new('key1') # Same as secret1

      hash = {}
      hash[secret1] = 'value1'
      hash[secret2] = 'value2'

      expect(hash.size).to eq(2)
      expect(hash[secret3]).to eq('value1') # Same key as secret1
    end
  end

  describe '#length' do
    it 'returns length without exposing value' do
      secret = SensitiveString.new('12345')
      expect(secret.length).to eq(5)
      expect(secret.size).to eq(5)
    end
  end

  describe '#empty?' do
    it 'returns true for empty value' do
      empty = SensitiveString.new('')
      not_empty = SensitiveString.new('value')

      expect(empty).to be_empty
      expect(not_empty).not_to be_empty
    end
  end

  describe 'immutability' do
    it 'freezes the value' do
      secret = SensitiveString.new('value')
      expect(secret.value).to be_frozen
      expect(secret).to be_frozen
    end
  end

  describe '.sensitive_string?' do
    it 'identifies SensitiveString objects' do
      secret = SensitiveString.new('test')

      expect(SensitiveString.sensitive_string?(secret)).to be true
      expect(SensitiveString.sensitive_string?('plain')).to be false
      expect(SensitiveString.sensitive_string?(nil)).to be false
    end
  end

  describe '.extract_value' do
    it 'extracts value from SensitiveString or String' do
      secret = SensitiveString.new('secret')

      expect(SensitiveString.extract_value(secret)).to eq('secret')
      expect(SensitiveString.extract_value('plain')).to eq('plain')
      expect(SensitiveString.extract_value(nil)).to be_nil
    end
  end

  describe '.extract_required_value' do
    it 'extracts value or raises error' do
      secret = SensitiveString.new('secret')

      expect(SensitiveString.extract_required_value(secret)).to eq('secret')
      expect(SensitiveString.extract_required_value('plain')).to eq('plain')
      expect { SensitiveString.extract_required_value(nil) }.to raise_error(ArgumentError)
    end
  end

  describe '.sensitive' do
    it 'converts to SensitiveString' do
      secret = SensitiveString.new('original')

      # Already sensitive - returns same object
      result = SensitiveString.sensitive(secret)
      expect(result).to eq(secret)

      # Convert string
      result = SensitiveString.sensitive('plain')
      expect(result).to be_a(SensitiveString)
      expect(result.value).to eq('plain')

      # nil stays nil
      expect(SensitiveString.sensitive(nil)).to be_nil

      # Other types get stringified
      result = SensitiveString.sensitive(123)
      expect(result.value).to eq('123')
    end
  end
end

