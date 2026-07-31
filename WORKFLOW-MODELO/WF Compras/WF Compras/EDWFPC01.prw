#include "protheus.ch"
#include "topconn.ch"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  | EDWFPC01  ºAutor  ³ Luciano Siqueira  º Data ³  19/03/24   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Rotina de envio de workflow de aprovação de compras 		  º±±
±±º          ³                                  						  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ\ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ EDEBE  		                                              º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

user function EDWFPC01()

    Local aArea     := getArea()
    Local aAreaSC7  := SC7->(getArea())
    Local aAreaSA2  := SA2->(getArea())
    Local cTo       := ""
	Local cNumPed   := ""
	Local cAprov	:= ""
	Local cObs		:= ""
	Local cStatus   := ""
	Local cURLWF	:= getNewPar("ZZ_URLWF", "172.50.0.6:9595/WF") //"200.232.119.74:9595/WF"
	Local cEmpWF	:= getNewPar("ZZ_EMPWF", "emp01") 
	Default cNivel 	:= "01"

	//200.166.192.162:8010/WF
	//cURLWF	:= "172.50.0.6:8010/WF"

	//Função que da o Start no Workflow
	oProcess := TWFProcess():New("WFPEDCOM", "Workflow de Aprovação de Pedido de Compras")
	// //Função que busca o Modelo do HTML
	oProcess:NewTask("000003", "\WORKFLOW\modelos_workflow\WFAPROVACAO.HTM")
	// //Subject do Email
	
	oProcess:cSubject := "Workflow de Aprovação de Pedido de Compras " + SC7->C7_NUM

	oProcess:bReturn := "U_EDWFPC02()"

	oProcess:fDesc := "Pedido de Compra Nº " + SC7->C7_NUM

	SA2->(dbSetOrder(1)) //A2_FILIAL + A2_COD + A2_LOJA
	SA2->(dbSeek(xFilial("SA2") + SC7->C7_FORNECE + SC7->C7_LOJA))

	cSolicit := usrFullName(SC7->C7_USER)
	cDesTipo := "PEDIDO DE COMPRA"

	If Funname() == "MATA122" .OR. SC7->C7_TIPO == 2//Autorização de Entrega
		dbSelectArea("SC3")
		dbSetOrder(1)
		If dbSeek(xFilial("SC3")+SC7->(C7_NUMSC+C7_ITEMSC))
			cSolicit := usrFullName(SC3->C3_USER)
			cDesTipo := "AUTORIZACAO DE ENTREGA"
		Endif
	Endif

	oHTML := oProcess:oHTML
	oHTML:ValByName('TP_ITEM'	, "Itens do Pedido de Compra")
	oHTML:ValByName('TIPO'		, cDesTipo)
	oHTML:ValByName('CODIGO'	, SA2->A2_COD)
	oHTML:ValByName('TP_NOME'	, "Fornecedor")
	oHTML:ValByName('NOME'		, SA2->A2_NOME)
	oHTML:ValByName('NUM_PED'	, SC7->C7_NUM)
	oHTML:ValByName('EMISSAO'	, SC7->C7_EMISSAO)
	oHTML:ValByName('COND'		, SC7->C7_COND)
	oHTML:ValByName('E4_DESCRI'	, posicione("SE4", 1, xFilial("SE4") + SC7->C7_COND, "E4_DESCRI"))
	oHTML:ValByName('CGC'		, transform(SA2->A2_CGC, pesqPict("SA2", "A2_CGC")))
	oHTML:ValByName('SOLICIT'	, cSolicit)

    oHTML:ValByName('C7_FILIAL'	, SC7->C7_FILIAL)
	oHTML:ValByName('C7_NUM'	, SC7->C7_NUM)

	cAssunto := "PEDIDO DE COMPRA Nº " + SC7->C7_NUM

	nVlrTotal	:= 0
	cNumPed		:= SC7->C7_NUM
	cChave		:= alltrim(SC7->C7_FILIAL) + alltrim(SC7->C7_NUM)
	
	SC7->(dbSetOrder(1))
	SC7->(dbSeek(cChave))
	while !SC7->(EoF()) .And. alltrim(SC7->C7_FILIAL) + alltrim(SC7->C7_NUM) == cChave
		cProduto	:= 	SC7->C7_PRODUTO
		nSaldo		:= 	SC7->(C7_QUANT-C7_QUJE)
		If Funname() == "MATA122" .OR. SC7->C7_TIPO == 2//Autorização de Entrega
			dbSelectArea("SC3")
			dbSetOrder(1)
			If dbSeek(xFilial("SC3")+SC7->(C7_NUMSC+C7_ITEMSC))
				nSaldo	:= 	SC3->(C3_QUANT-C3_QUJE)
			Endif
		Endif

		aadd((oHtml:ValByName('item.ITEM'))	    , SC7->C7_ITEM)
		aadd((oHtml:ValByName('item.PROD'))	    , alltrim(SC7->C7_PRODUTO))
		aadd((oHtml:ValByName('item.DESCRI'))   , encodeUTF8(SC7->C7_DESCRI))
		aadd((oHtml:ValByName('item.QUANT'))	, transform(SC7->C7_QUANT, pesqPict("SC7", "C7_QUANT")))
		aadd((oHtml:ValByName('item.SALDO'))	, transform(nSaldo, pesqPict("SC7", "C7_QUANT")))
		aadd((oHtml:ValByName('item.UM'))	    , SC7->C7_UM)
		aadd((oHtml:ValByName('item.CONTA'))	, alltrim(SC7->C7_CONTA) + " - " + alltrim(getAdvFVal("CT1", "CT1_DESC01", xFilial("CT1")+SC7->C7_CONTA, 1, "")))
		aadd((oHtml:ValByName('item.CC'))	    , alltrim(getAdvFVal("CTT", "CTT_DESC01", xFilial("CTT")+SC7->C7_CC, 1, "")))
		aadd((oHtml:ValByName('item.ITEMCTA'))	, alltrim(getAdvFVal("CTD", "CTD_DESC01", xFilial("CT1")+SC7->C7_ITEMCTA, 1, "")))
		aadd((oHtml:ValByName('item.PRECO'))	, transform(SC7->C7_PRECO, PesqPict("SC7","C7_PRECO")))
		aadd((oHtml:ValByName('item.TOTAL'))	, transform(SC7->C7_TOTAL, PesqPict("SC7", "C7_TOTAL")))

		// Tratamento para o campo de observação
		if len(alltrim(SC7->C7_OBSM)) > 0
			cObs += alltrim(SC7->C7_OBSM) + "<br>"
		endif

		nVlrTotal += SC7->C7_TOTAL
		SC7->(dbSkip())
	end

	oHtml:ValByName("VLRTOT"	, transform(nVlrTotal, pesqPict("SC7", "C7_TOTAL")))
	oHtml:ValByName("OBSERVACAO", cObs)

	cTipo := AVKEY("PC","CR_TIPO")

	If Funname() == "MATA122"
		cTipo := AVKEY("AE","CR_TIPO")
		cAssunto := "AUTORIZAÇÃO DE ENTREGA Nº " + cNumPed//SC7->C7_NUM
	Else		
		SCR->(dbSetOrder(1)) // CR_FILIAL+CR_TIPO+CR_NUM+CR_NIVEL
		if SCR->(!dbSeek(xFilial("SCR") + cTipo + cNumPed))
			cTipo := AVKEY("IP","CR_TIPO")
		Endif 
	Endif

	SCR->(dbSetOrder(1)) // CR_FILIAL+CR_TIPO+CR_NUM+CR_NIVEL
	if SCR->(dbSeek(xFilial("SCR") + cTipo + cNumPed))
		while !SCR->(eof()) .and. SCR->(CR_FILIAL+CR_TIPO+CR_NUM) == xFilial("SCR") + AVKEY(cTipo,"CR_TIPO") + AVKEY(cNumPed,"CR_NUM")//alltrim(SCR->CR_FILIAL) + alltrim(SCR->CR_NUM) == cChave
			if alltrim(SCR->CR_STATUS) == "02"
				cAprov := alltrim(SCR->CR_USER)
				cTo := usrRetMail(SCR->CR_USER)
				oHTML:ValByName('RECNO'	, SCR->(recno()))
				oHTML:ValByName('GRUPO'		, SCR->CR_GRUPO + " - " + getAdvFVal("SAL", "AL_DESC", xFilial("SAL")+SCR->CR_GRUPO, 1, ""))
			endif
			aadd((oHtml:ValByName('apv.NIVEL'))		, SCR->CR_NIVEL)
			aadd((oHtml:ValByName('apv.APROV'))		, usrFullName(SCR->CR_USER))
			if SCR->CR_STATUS == "01"
				cStatus := "Aguardando nivel anterior"
			elseif SCR->CR_STATUS=="02"
				cStatus := "Em Aprovacao"
			elseif SCR->CR_STATUS=="03"
				cStatus := "Aprovado"
			endif
			aadd((oHtml:ValByName('apv.STATUS'))	, cStatus)
			aadd((oHtml:ValByName('apv.COMENT'))	, SCR->CR_OBS)

			SCR->(dbSkip())
		end
	endif

	oHTML:ValByName('USER'		, cAprov)
	oHTML:ValByName('APROVADOR'	, usrFullName(cAprov))
	
	oProcess:cTo := "WFAPROVACAO"
	// //Identifica ID do usuario
	oProcess:UserSiga := __cUserID
	cMailId := oProcess:Start()
	
	cBody := "<b>Sr(a). " + alltrim(usrFullName(cAprov)) + "</b><br><br>"
	cBody += "Preparamos esse documento para sua aprovação.<br>"
	cBody += "Clique no botão abaixo para abrir o documento.<br>"

	cFooter := "Atenciosamente, " + "<br>"
	cFooter += "Workflow Protheus | Servico de Mensagens" + "<br>"

	cHtmlModelo := "\workflow\modelos_workflow\wflink.htm"
	//cTo := "vleonardo@deltadecisao.com.br"//'loliveira@deltadecisao.com.br'
	oProcess:NewTask(cAssunto, cHtmlModelo)
	oProcess:cSubject := cAssunto
	oProcess:cTo := Alltrim(cTo)

	oProcess:oHtml:ValByName("BODY"	    , cBody)
	oProcess:oHtml:ValByName("FOOTER"	, cFooter)
	oProcess:oHtml:ValByName("WLink"	, "http://" + alltrim(cURLWF) + "/messenger/" + alltrim(cEMPWF) + "/wfaprovacao/" + cMailID + ".htm")
	oProcess:Start()

    restArea(aAreaSA2)
    restArea(aAreaSC7)
    restArea(aArea)

    conout("Fim EDWFPC01")

return
