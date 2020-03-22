# Remove all old admin
Admin.destroy_all

# Create new admin
Admin.create!({
  email: 'ben.tran@futureworkz.com',
  password: '123123', 
  password_confirmation: '123123'
})
