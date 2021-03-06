require "uniswap.k"

module MAKER-SYNTAX
	   imports UNISWAP-SYNTAX

	   syntax MakerTX ::= ETHAddress "opens vault" ETHAddress
	   | ETHAddress "locks" Int "collateral to vault" ETHAddress
	   | ETHAddress "draws" Int "debt from vault" ETHAddress
	   | ETHAddress "wipes" Int "debt from vault" ETHAddress
	   | ETHAddress "frees" Int "collateral from vault" ETHAddress
	   | ETHAddress "bites vault" ETHAddress
	   | ETHAddress "is given vault" ETHAddress
	   
       syntax ETHTransaction ::= MakerTX
       syntax ETHAddress ::= "SAI"

endmodule

module MAKER
	   imports MAKER-SYNTAX
	   imports UNISWAP

    //configuration
    //<maker>
    //<V> .Map </V> // Mapping of Maker Vault to Owner
    //</maker>

// TODO : add stability fees (interest)

syntax Statement ::= "DONE"
	   			 	 | "FAIL"


rule
	 <k> exec(Address:ETHAddress opens vault Vault:ETHAddress) => .K </k>
     <V> V => V[(Vault) <- Address:ETHAddress] </V>
     <S> B => B[(Vault in 0) <- 0:Int][(Vault in SAI) <- 0:Int] </S> 
     <B> ... .List => ListItem(Address opens vault Vault) </B>
     requires notBool((Vault in 0) in keys(B)) andBool notBool((Vault in SAI) in keys(B)) andBool notBool((Vault) in keys(V))

rule
     <k> exec(Address:ETHAddress locks Amount:Int collateral to vault Vault:ETHAddress) =>
     	 Address in 0 gets (0 -Int Amount) ~>
		 Vault in 0 gets Amount
     </k>  
     <V> ... Vault |-> Address ... </V>
     <B> ... .List => ListItem(Address locks Amount collateral to vault Vault) </B>
     
rule
     <k> exec(Address:ETHAddress draws Amount:Int debt from vault Vault:ETHAddress) =>
         Address in SAI gets Amount ~>
	 	 Vault in SAI gets Amount
     </k>  
     <V> ... Vault |-> Address ... </V>
     <P> ... (0 , SAI) |-> Px ... </P>
     <S> ... (Vault in 0) |-> TotalCollateral (Vault in SAI) |-> TotalDebt  ... </S>
     <B> ... .List => ListItem(Address draws Amount debt from vault Vault) </B>
     requires TotalCollateral *Int Px *Int 100 >=Int 150 *Int (TotalDebt +Int Amount)

rule
     <k> exec(Address:ETHAddress frees Amount:Int collateral from vault Vault:ETHAddress) =>
         Address in 0 gets Amount ~>
	 	 Vault in 0 gets (0 -Int Amount)
     </k>  
     <V> ... Vault |-> Address ... </V>
     <P> ... (0 , SAI) |-> Px ... </P>
     <S> ... (Vault in 0) |-> TotalCollateral (Vault in SAI) |-> TotalDebt  ... </S>
     <B> ... .List => ListItem(Address frees Amount collateral from vault Vault) </B>
     requires (TotalCollateral -Int Amount) *Int Px *Int 100 >=Int 150 *Int TotalDebt

rule
     <k> exec(Address:ETHAddress wipes Amount:Int debt from vault Vault:ETHAddress) =>
         Address in SAI gets (0 -Int Amount) ~>
		 Vault in SAI gets (0 -Int Amount)
     </k>  
     <V> ... Vault |-> Address ... </V>
     <S> ... (Vault in SAI) |-> TotalDebt  ... </S>
     <B> ... .List => ListItem(Address wipes Amount debt from vault Vault) </B>
     requires (TotalDebt >=Int Amount)

rule
     <k> exec(Address:ETHAddress bites vault Vault:ETHAddress) =>
         Vault in SAI gets (0 -Int TotalDebt) ~>
	 	 Vault in 0 gets 0 -Int ((130 *Int TotalDebt) /Int (Px *Int 100)) ~> // 30% penalty
	 	 Address in SAI gets TotalDebt ~>
	 	 Address in 0 gets (0 -Int ((90 *Int TotalDebt) /Int (Px *Int 100)) ) //10% discount
     </k>  
     <P> ... (0 , SAI) |-> Px ... </P>
     <S> ... (Vault in 0) |-> TotalCollateral (Vault in SAI) |-> TotalDebt  ... </S>
     <B> ... .List => ListItem(Address bites vault Vault) </B>
     requires (TotalCollateral *Int Px *Int 100 <Int 150 *Int TotalDebt) andBool (Px >Int 0)

rule
     <k> exec(_ bites vault _) => FAIL </k>  
     <B> ... .List => ListItem(FAIL) </B>


rule
     <k> exec(_ draws _ debt from vault _) => FAIL </k>  
     <B> ... .List => ListItem(FAIL) </B>

rule
	 <k> exec(_ locks _ collateral to vault _) => FAIL </k>
     <B> ... .List => ListItem(FAIL) </B>


rule
	 <k> exec(_ opens vault _) => FAIL </k>
     <B> ... .List => ListItem(FAIL) </B>

rule
     <k> exec(_ is given vault _) => FAIL </k>  
     <B> ... .List => ListItem(FAIL) </B>


rule
     <k> exec(Address:ETHAddress is given vault Vault:ETHAddress) => .K </k>  
     <V> ... Vault |-> (_ => Address)  ... </V>
     <B> ... .List => ListItem(Address is given vault Vault) </B>

rule
	 <k> .K => DONE </k>
	 <M> .Set </M>


endmodule

	   