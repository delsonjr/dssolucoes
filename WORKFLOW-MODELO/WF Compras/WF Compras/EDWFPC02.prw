#include "protheus.ch"
#include "topconn.ch"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  | EDWFPC02  ºAutor  ³ Luciano Siqueira  º Data ³  19/03/24   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Rotina de retorno do workflow de aprovação de compras	  º±±
±±º          ³                                  						  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ\ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ EDEBE  		                                              º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

user function EDWFPC02(oProcess)

	Local cFilPed   := oProcess:oHtml:RetByName('C7_FILIAL')
	Local cNum 	    := oProcess:oHtml:RetByName('C7_NUM')
	Local nRecno 	:= oProcess:oHtml:RetByName('RECNO')
	Local lAprov 	:= right(Alltrim(Upper(oProcess:oHtml:RetByName('aprovacao'))),1) == "S"
	Local lAllApv   := .T.

	SC7->(dbSetOrder(1))
	if SC7->(dbSeek(xFilial("SC7") + AVKEY(cNum,"C7_NUM")))
		SCR->(dbGoTo(nRecno))
		//Verifica se o registro posicionado está pendente de aprovação
		if SCR->CR_STATUS <> "02"
			return
		endif

		if lAprov
			lLiberou := MaAlcDoc({SCR->CR_NUM,SCR->CR_TIPO,SCR->CR_TOTAL,SCR->CR_APROV,,SCR->CR_GRUPO,,,,,oProcess:oHtml:RetByName('MOTIVO')}, date(),4)
		else
			lLiberou := MaAlcDoc({SCR->CR_NUM,SCR->CR_TIPO,,SCR->CR_APROV,,SCR->CR_GRUPO,,,,dDataBase,oProcess:oHtml:RetByName('MOTIVO')}, date(), 7)
			SCR->(reclock("SCR", .F.))
			SCR->CR_OBS := alltrim(oProcess:oHtml:RetByName('MOTIVO'))
			SCR->(msunlock())
		endif
	endif

	cTipo := AVKEY("PC","CR_TIPO")

	SCR->(dbSetOrder(1)) // CR_FILIAL+CR_TIPO+CR_NUM+CR_NIVEL
	if SCR->(!dbSeek(xFilial("SCR") + cTipo + cNum))
		cTipo := AVKEY("IP","CR_TIPO")
	Endif

	// Executa ponto de entrada para verificar se há mais níveis de aprovação
	SCR->(dbSetOrder(1)) // CR_FILIAL+CR_TIPO+CR_NUM+CR_NIVEL
	if SCR->(dbSeek(xFilial("SCR") + cTipo + AVKEY(cNum,"CR_NUM")))
		while !SCR->(eof()) .and.SCR->(CR_FILIAL+CR_TIPO+CR_NUM) == AVKEY(cFilPed,"CR_FILIAL") + AVKEY(cTipo,"CR_TIPO") + AVKEY(cNum,"CR_NUM")//alltrim(SCR->CR_FILIAL) + alltrim(SCR->CR_NUM) == cFilPed + cNum
			if SCR->CR_STATUS == "02"
				lAllApv := .F.
				SC7->(dbSetOrder(1))
				if SC7->(dbSeek(xFilial("SC7") + AVKEY(cNum,"C7_NUM")))
					u_EDWFPC01()
					exit
				endif
			elseif SCR->CR_STATUS == "06"
				EDNotif(.F., cNum)
				lAllApv := .F.
				while !SC7->(eof()) .and. SC7->C7_FILIAL == AVKEY(cFilPed,"C7_FILIAL") .and. SC7->C7_NUM == AVKEY(cNum,"C7_NUM")
					SC7->(recLock("SC7", .F.))
					SC7->C7_CONAPRO := "R"
					SC7->(msUnlock())
					SC7->(dbSkip())
				end
				exit
			endif
			SCR->(dbSkip())
		end
		if lAllApv
			if SC7->(dbSeek(xFilial("SC7") + AVKEY(cNum,"C7_NUM")))
				EDNotif(.T., cNum)
				while !SC7->(eof()) .and. SC7->C7_FILIAL == AVKEY(cFilPed,"C7_FILIAL") .and. SC7->C7_NUM == AVKEY(cNum,"C7_NUM")
					SC7->(recLock("SC7", .F.))
					SC7->C7_CONAPRO := "L"
					SC7->(msUnlock())
					SC7->(dbSkip())
				end
			endif
		endif
	endif

	oProcess:Finish()
	oProcess:Free()

return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  | EDNotif   ºAutor  ³ Luciano Siqueira  º Data ³  19/03/24   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função de notificação de aprovação/rejeição do workflow	  º±±
±±º          ³                                  						  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ\ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Gulf 		                                              º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

static function EDNotif(lStatus, cReg)

	Local oNotifica
	//Local cUser 	:= ""
	Local cBody		:= ""

	SC7->(dbSetOrder(1))
	SC7->(dbSeek(xFilial("SC7") + cReg))

	//Função que da o Start no Workflow
	oNotifica := TWFProcess():New("WFNOTIF", "E-mail de Notificação de Pedido de Compra")
	//Função que busca o Modelo do HTML
	oNotifica:NewTask("000004", "\WORKFLOW\modelos_workflow\WFNOTIFICA.HTM")
	//Subject do Email
	oNotifica:cSubject := "PEDIDO DE COMPRA Nº " + SC7->C7_NUM + " - " +  iif(lStatus,"APROVADO", "REJEITADO")

	cBody := "<b>Sr(a). " + usrFullName(SC7->C7_USER) + "</b><br><br>"
	cBody += "Notificamos a " + iif(lStatus,"aprovação", "rejeição") + " do pedido de compra nº <b>" + SC7->C7_NUM + "</b>"
	if len(alltrim(SCR->CR_OBS)) > 0
		cBody += "<br>Motivo: " + alltrim(SCR->CR_OBS) + "<br><br>"
	else
		cBody += "<br><br>"
	endif

	cBody += "Atenciosamente, " + "<br>"
	cBody += "Workflow Protheus | Servico de Mensagens" + "<br>"

	oNotifica:oHtml:ValByName("BODY", cBody)

	oNotifica:cTo := usrRetMail(SC7->C7_USER)

	//oNotifica:cTo := "vleonardo@deltadecisao.com.br"//'loliveira@deltadecisao.com.br'

	oNotifica:Start()
	oNotifica:Free()

return
