class User < ApplicationRecord
  mount_uploader :image_url, ImageUploader

  has_secure_password

  before_create :generate_token

  validates :email, presence: true, uniqueness: true

  has_many :posts, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorite_posts, through: :favorites, source: :post

  TOKEN_COOKIE_NAME = "dev_session_token".freeze

  def self.signin_credentials(email, password)
    user = find_by(email:)

    unless user && user.authenticate(password)
      raise Errors.create(:login_email_and_password_mismatch)
    end

    user
  end

  def reset_token!
    self.token = SecureRandom.alphanumeric(32)
    self.save!
  end

  def generate_token
    self.token = SecureRandom.alphanumeric(32)
  end

  def create_token_cookie(context)
    context[:response].set_cookie(
      TOKEN_COOKIE_NAME,
      {
        value: self.token,
        expires: 1.year.from_now,
        http_only: true,
        secure: Rails.env.production?,
      },
    )
  end

  def delete_session_cookie!(context)
    context[:response].delete_cookie(TOKEN_COOKIE_NAME)
    update!(token: nil)
  end
end
