# frozen_string_literal: true

def stub_account_keygens!
  allow_any_instance_of(Account).to receive(:private_key) { "-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEAzPAseDYupK78ZUaSbGw7YyUCCeKo/1XqTACOcmTTHHGgeHac\nLK2j9UrbTlhW5h8Vyo0iUEHrY1Kgf4wwiGgFh0Yc+oDWDhq1bIertI03AE420Lbp\nUf6OTioX+nY0EInxXF3J7aAdx/R/nYgRJrLZ9ATWaQVSgf3vtxCtCwUeKxKZI41G\nA/9KHTcCmd3BryAQ1piYPr+qrEGf2NDJgr3WvVrMtnjeoordAaCTyYKtfm56WGXe\nXr43dfdejBuIkI5kqSzwVyoxhnjE/Rj6xks8ffH+dkAPNwm0IpxXJerybjmPWyv7\niyXEUN8CKG+6430D7NoYHp/c991ZHQBUs59gvwIDAQABAoIBAHb03ks04CQ1cknz\nCeEnfd1RyPol+ASmQSa2l/isr6HuDsB90K9aZzZlqiCyxFY1Kvf0rjs52EFB3+nJ\nXQ6AmtznhMCfciCjvjVuFuvpoEhsHgNOeOZgRQf4BQ0b+aKz/0anJiPpcf/z2vN8\n3L/CxyKOgEpbjYXo+XEgm+EuqlFDI3UZqhqFBTTf550QazjOihpItAMzf5yHP20Q\n8lA8PzYyYdkKqxdnaOt1IwhF+yFw2exZYPdHoWzmE/fI6RhQ5UyD9pidzBuW4xdH\nZQbWnsXPK7ZzNqN3Y1TkHl1TLPOKA0Ge5X/lcyCKB4v8zCVPUHOrVGDrsrHEc08P\nxCi52PkCgYEA5914ulPHrBN/h/G2nA45R1SE6QgFKPGQk8HaplV788aN+X73JNv5\nL8vSlhUJsUuGwuRkJkslxy/cA8do/39hSKESx2Tuu8EUeinCID26l1p4eczFoqps\nT7h4ggRsrJbN78bndG7ZkNQJPK2fEmZ/hp8XT9cJhgy2YwfUwydtLA0CgYEA4kUt\ne+7jlj7tQH5H/7ZpLhwckMNYr9Ojm8qCy+t40TAxVMBuGDfWhldMIjyzDU8wj9dr\nuKaejQ83jWqFlt/qbb1NFrLL7QKJajDlujI9hh55mG+jUa/bgfShuJnlMXPpCz+K\njhO5edT/jE4br3PgEAdnkbwVIJ8E+6vpjMQt8PsCgYAAoh85Sw9JjggUI/netT88\nzaNLS6VP9lDxxl7Fg4hCIzGyE8GzDRLCKalalZYgMNeeYqdPX3cr8xqDvCCySfPH\nEgGOH91zD9TxfHm2QtTmou2fT4repd6D3TofCMoPMp4/YGizbbYUai/YRZUgpL0G\nbhrPMgQppJE+9f+DxPDMZQKBgQCOG3RdicNV8V+ASc9eQmn8k5s9L/LbOsheZ+mN\nuO3AM8xHtjNu8mLBLMKcHhM2IK4XKOx2o+6gGRaCsowEHc1V7rYjs1dwG0/CacNe\nFX+eZDVqD3M7Mn9iNwn6rmzLikiqz9VtNeYfJi75J3Ur1FK8vmnFlaKPQlAW3/lm\ndy+DUQKBgEkNkmfafNVzCUZhgB5NDF1HNOqlPM0R9UrDraarG4pH7tVsl6lkEIc9\nujJSB6CauUNGVSx5zhiGXKLTYoQRTEWmdbBR0NK9EaK4icCTR+0cFS/jBpS4rJW8\n6hlMaiHG6DNtYdVbgtVqVC3EAXWrjfAPqBwoHP4CWq/vYfLK/53I\n-----END RSA PRIVATE KEY-----\n" }
  allow_any_instance_of(Account).to receive(:public_key) { "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzPAseDYupK78ZUaSbGw7\nYyUCCeKo/1XqTACOcmTTHHGgeHacLK2j9UrbTlhW5h8Vyo0iUEHrY1Kgf4wwiGgF\nh0Yc+oDWDhq1bIertI03AE420LbpUf6OTioX+nY0EInxXF3J7aAdx/R/nYgRJrLZ\n9ATWaQVSgf3vtxCtCwUeKxKZI41GA/9KHTcCmd3BryAQ1piYPr+qrEGf2NDJgr3W\nvVrMtnjeoordAaCTyYKtfm56WGXeXr43dfdejBuIkI5kqSzwVyoxhnjE/Rj6xks8\nffH+dkAPNwm0IpxXJerybjmPWyv7iyXEUN8CKG+6430D7NoYHp/c991ZHQBUs59g\nvwIDAQAB\n-----END PUBLIC KEY-----\n" }
  allow_any_instance_of(Account).to receive(:generate_rsa_keys!) { true }

  allow_any_instance_of(Account).to receive(:ed25519_private_key) { '7e122ed891de6dcaf5316a2f0e09187fbf3fa5b5441cb835a67b53d8c87eafc5' }
  allow_any_instance_of(Account).to receive(:ed25519_public_key) { '799efc7752286e6c3815b13358d98fc0f0b566764458adcb48f1be2c10a55906'}
  allow_any_instance_of(Account).to receive(:generate_ed25519_keys!) { true }
end

# FIXME(ezekg) Caching breaks due to stubbing
def stub_cache!
  allow(Rails.cache).to receive(:fetch) { |&block| block.call }
end

def stub_s3!
  Aws.config[:s3] = { stub_responses: { delete_object: [], head_object: [] } }
end
