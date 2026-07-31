#include "protheus.ch"
#include "TbiConn.ch"
#include "TbiCode.ch"
#include "topconn.ch"
#Include 'ApWebEx.ch'

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³WFW120P   ºAutor  ³Luciano Siqueira    º Data ³  24/08/2024 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³PE na gravacao do Pedido de compras para ativacao de WF     º±±
±±º          ³do controle de alcadas                                      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Edebe                                                      º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function WFW120P()

	Local aArea := GetArea()
	Local lAprov:= .F.

	cQuery := " SELECT * "
	cQuery += "	FROM "+RetSqlName("SC7")+" SC7 (NOLOCK)"
	cQuery += "	WHERE "
	cQuery += "		C7_FILIAL = '"+xFilial("SC7")+"' AND "
	cQuery += "		C7_NUM = '"+SC7->C7_NUM+"' AND "
	cQuery += "		C7_CONAPRO = 'B' AND "
	cQuery += "		SC7.D_E_L_E_T_='' "

	If Select("TSQC7") > 0
		dbSelectArea("TSQC7")
		TSQC7->(dbCloseArea())
	EndIf

	dbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), "TSQC7", .F., .F.)

	dbSelectArea("TSQC7")
	TSQC7->(dbGotop())
	If TSQC7->(!EOF())
		lAprov:= .T.		
	Endif

	If Select("TSQC7") > 0
		dbSelectArea("TSQC7")
		TSQC7->(dbCloseArea())
	EndIf

	If lAprov
		u_EDWFPC01()
	Endif

	RestArea(aArea)

Return

