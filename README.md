
# ขั้นตอน
# 1.regiater userผ่าน http://127.0.0.1:8000/Smartwityouapp/Register/  โดยใช้ bodyที่เเนบไปกับrequestตามนี้  {
    "email": "bangaro644@gmail.com",
    "username":"tairone",
    "age":20,
    "gender":"man",
    "password":"tttt4321"

} ถ้าขึ้น request error 500 ไม่ต้องสนใจเเพราะมันเกี่ยวกับfrontend 


# 2.user สำหรับทดสอบpath http://127.0.0.1:8000/Smartwityouapp/Login/    (เป็นPOST) คือ emali: bangaro644@gmail.com password: tttt4321  
#เนื่องจากbackendผมทำหน้าที่เป็นapiที่ไว้คุยกัยไคลเอนท์ที่เป็นflutter เลยไม่มีหน้าเว็บหรือtemplate ต้องทดสอบผ่านpostman หรือ อื่นเอานะครับ 


# 1. clone project
# 2. สร้าง env เเละเปิดใช้งาน
# 3. ใช้ คำสั่ง pip install -r requirement.txt
# 4. https://docs.google.com/document/d/1xgJ1eGZI4EfC7coXaC04U1hc2PtXISrQTiBHkPKdNAE/edit?usp=sharing เข้าไปลิกเอกสาารเเล้วเอาคีย์ไปใส่ 
# 5. makemigrationsเเละmigrate 
# 6. cd ไปที่ PS D:\ci-cd\CI-CD_project\backend-django\backend เเล้วใช้ python manage.py  runserver
# 7. เปิดเทอมินอลใหม่เเล้ว cd myflutterproject เเล้ว ใช้คำสั่ง flutter pub get  
# 9. ก็อป key ของ google service ที่อยู่ในเอกสารมาใส่
# 8. เปิด emulator  เเล้วใช้คำสั่ง fluutter run
