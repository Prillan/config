let
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIIUX5FPGayQ3wk/0akNTfY9TOEdfB2ntZHJxWbwtIcP";
  server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGiBKV/Losb/wqIh55IDpmM5gbhN6v25ndLN3F5M7jZO";
  work = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDiNDKF1SreuifGMuYOwZFwoyf0bgiq87EcWaq6THPk9";
in
{
  "telegram-token.age".publicKeys = [ user server work ];
}
