let user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIIUX5FPGayQ3wk/0akNTfY9TOEdfB2ntZHJxWbwtIcP";
in {
  "secrets/telegram-token.age".publicKeys = [ user ];
}
