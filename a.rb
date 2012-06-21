require 'sinatra'
require 'mysql'

get '/crear/nuevo' do
	my = Mysql::new("localhost", "root", "asdasd", "sac")
	my.query("insert into conversacion VALUES();")
	res = my.query("select * from conversacion ORDER BY ID DESC LIMIT 1;")
	res.each do |r|
		redirect "/crear/#{r[0]}"	
	end
end
get '/crear/:cid' do
	my = Mysql::new("localhost", "root", "asdasd", "sac")
	res = my.query("select * from Mensajes WHERE ConversacionID = '#{params[:cid]}'")
	res2 = my.query("select * from Respuestas r, Mensajes m WHERE ConversacionID = '#{params[:cid]}' AND r.MensajeID = m.ID;")
	link = request.url.sub("crear", "responder")	
	erb :index, :locals => {:mensajes => res, :respuestas => res2, :cid => params[:cid], :link => link}
	
end

post '/crear/:cid' do
	my = Mysql::new("localhost", "root", "asdasd", "sac")

	link = request.url.sub("crear", "responder")
	mensajeID = "NULL"
	respuestaID = "NULL"
	if params[:origen].include? 'm'
		mensajeID = params[:origen].split('m').last
	elsif params[:origen].include? 'r'
		respuestaID = params[:origen].split('r').last
	end
	my.query("insert into Mensajes(ConversacionID, Mensaje, Tipo_Declaracion, MensajeAnterior, BasadoRespuesta) VALUES "+
	"('#{params[:cid]}', '#{params[:declaracion]}', '#{params[:tipo]}', '#{mensajeID}', '#{respuestaID}'); update Mensajes set MensajeAnterior = NULL, BasadoRespuesta = NULL Where MensajeAnterior=0 AND BasadoRespuesta=0;")
	res = my.query("select ID from Mensajes WHERE Mensaje = '#{params[:declaracion]}' AND Tipo_Declaracion = '#{params[:tipo]}' AND ConversacionID = '#{params[:cid]}'")
	if params[:tipo] == "FREE"
		res.each do |row|
			my.query("insert into Respuestas(MensajeID, Texto) VALUES "+
				"('#{row[0]}', '#{params[:respuestas]}')")
		end
	
	elsif
		res.each do |row|
			params[:respuestas].each do |respuesta|
			my.query("insert into Respuestas(MensajeID, Texto) VALUES "+
			"('#{row[0]}', '#{respuesta}')")
			end	
		end
	end
	res = my.query("select * from Mensajes WHERE ConversacionID = '#{params[:cid]}'")
	res2 = my.query("select * from Respuestas r, Mensajes m WHERE ConversacionID = '#{params[:cid]}' AND r.MensajeID = m.ID AND m.Tipo_Declaracion <> 'FREE';")
	erb :index2, :locals => {:mensajes => res, :respuestas => res2, :link => link}
	
end

get '/responder/:cid' do
	my = Mysql::new("localhost", "root", "asdasd", "sac")
	men = my.query("select * from Mensajes where ConversacionID = '#{params[:cid]}' LIMIT 1;")
	mensajeid = ""
	mensaje = ""	
	men.each do |m|
		mensaje = m[2]
		mensajeid = m[0]	
	end
	res = my.query("select * from Respuestas where MensajeID = '#{mensajeid}';")
	erb :responder, :locals => {:mensaje => mensaje, :mensajeid => mensajeid, :respuestas => res}
end

post '/responder' do
	my = Mysql::new("localhost", "root", "asdasd", "sac")
	respuestaid = params[:respuesta]
	texto = params[:texto]
	my.query("insert into RespuestasHistorial(RespuestaID, Texto) VALUES ('#{respuestaid}', '#{texto}')")
	men = my.query("select * from Mensajes where BasadoRespuesta = '#{respuestaid}';")
	if men.num_rows() == 0
	men = my.query("select * from Mensajes where MensajeAnterior = '#{params[:mensajeid]}';")
	end
	
	mensajeid = ""
	mensaje = ""	
	men.each do |m|
		mensaje = m[2]
		mensajeid = m[0]	
	end
	res = my.query("select * from Respuestas where MensajeID = '#{mensajeid}';")
	erb :responder, :locals => {:mensaje => mensaje, :mensajeid => mensajeid, :respuestas => res}

end

get '/leer/:cid' do
	my = Mysql::new("localhost", "root", "asdasd", "sac")
	con = my.query("select * from Mensajes m, Respuestas r, RespuestasHistorial rh where m.ConversacionID = '#{params[:cid]}' and r.MensajeID = m.ID and rh.RespuestaID = r.ID;")
	erb :conversacion, :locals => {:conversacion => con}	
end
