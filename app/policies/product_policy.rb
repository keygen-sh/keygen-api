# frozen_string_literal: true

class ProductPolicy < ApplicationPolicy
  def index?
    verify_permissions!('product.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'user' } if record_ids & bearer.product_ids == record_ids
      allow!
    in role: { name: 'license' } if record == [bearer.product]
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('product.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' } if record == bearer
      allow!
    in role: { name: 'user' } if bearer.products.exists?(record.id)
      allow!
    in role: { name: 'license' } if record == bearer.product
      allow!
    else
      deny!
    end
  end

  def create?
    verify_permissions!('product.create')

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    else
      deny!
    end
  end

  def update?
    verify_permissions!('product.update')

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    in role: { name: 'product' } if record == bearer
      allow!
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('product.delete')

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    else
      deny!
    end
  end

  def me?
    verify_permissions!('product.read')

    case bearer
    in role: { name: 'product' } if record == bearer
      allow!
    else
      deny!
    end
  end
end
