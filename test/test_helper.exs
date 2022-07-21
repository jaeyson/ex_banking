Mox.defmock(ExBankingBehaviourMock, for: ExBankingBehaviour)
Application.put_env(:bound, :ex_banking, ExBankingBehaviourMock)

ExUnit.start()
