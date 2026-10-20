Copy `KreenGate/app/src/main/res/raw/gogetssl_intermediate.crt` into this folder.

Di app Android, sertifikat ini dipercaya khusus untuk `jipremium.com` lewat
`network_security_config.xml`. Di Flutter, `ApiService` memuatnya ke
`SecurityContext` client jipremium. Kalau file belum ada, client tetap jalan
dengan trust store bawaan sistem saja.
