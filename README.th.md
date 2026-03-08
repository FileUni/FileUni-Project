[English](./README.md) | [简体中文](./README.zh-CN.md) | [Deutsch](./README.de.md) | [Français](./README.fr.md) | [Italiano](./README.it.md) | [日本語](./README.ja.md) | [한국어](./README.ko.md) | [हिन्दी](./README.hi.md) | [Bahasa Indonesia](./README.id.md) | [Tiếng Việt](./README.vi.md) | [ไทย](./README.th.md)

# FileUni Project

**FileUni** คือแพลตฟอร์มจัดการไฟล์และระบบจัดเก็บข้อมูลยุคใหม่ที่พัฒนาด้วย Rust โดยเน้นประสิทธิภาพ ความปลอดภัย และการปรับใช้แบบแยกส่วน

ตั้งแต่อุปกรณ์ขนาดเล็กมากไปจนถึงเซิร์ฟเวอร์เต็มรูปแบบ FileUni ออกแบบมาเพื่อมอบความสามารถแบบ NAS โดยไม่ต้องใช้ฮาร์ดแวร์เฉพาะทาง พร้อมคงไว้ซึ่ง codebase เดียวที่ขยายต่อได้สำหรับ CLI, GUI และส่วนประกอบเว็บ

## รีโพซิทอรีนี้คืออะไร

รีโพซิทอรีนี้เป็นศูนย์กลางโครงการสาธารณะของ FileUni โดยใช้หลัก ๆ สำหรับ:

- เวิร์กโฟลว์ build และ release แบบอัตโนมัติ
- การติดตาม issue และ feedback แบบสาธารณะ
- การประสานงานโครงการกับชุมชน
- ปลายทางการซิงก์แบบ subtree

workspace การพัฒนาหลักอยู่ใน monorepo แบบส่วนตัว และมีการซิงก์บางส่วนมายังที่นี่เพื่อใช้สำหรับ release และการทำงานร่วมกันแบบสาธารณะ

## ทำไมต้อง FileUni

- สถาปัตยกรรมประสิทธิภาพสูงบน Rust
- การออกแบบแบบโมดูลาร์สำหรับหลายขนาดการปรับใช้
- ความสามารถแบบ NAS โดยไม่ต้องใช้ฮาร์ดแวร์เฉพาะ
- การเข้าถึงหลายโปรโตคอล เช่น FTP, SFTP, WebDAV และ S3
- มุ่งเน้นความเชื่อถือได้และความปลอดภัยสำหรับงานด้าน storage

## รีโพซิทอรีที่เกี่ยวข้อง

- [FileUni Website](https://fileuni.com/)
- [FileUni Repositories](https://github.com/FileUni?tab=repositories)
- [OfficialSiteDocs](https://github.com/FileUni/OfficialSiteDocs)
- [OfficialSitePrivate](https://github.com/FileUni/OfficialSitePrivate)
- [yh-filemanager-vfs-storage-hub](https://github.com/FileUni/yh-filemanager-vfs-storage-hub)

## การเปิดเผยซอร์สโค้ด

รีโพซิทอรีนี้มีส่วนโครงการสาธารณะของ FileUni และอาจมีการเปิดโมดูลเพิ่มเติมอย่างค่อยเป็นค่อยไปในอนาคต

ซอร์สโค้ดที่เผยแพร่มีไว้เพื่อการอ่าน การรีวิว การทำ release automation และการมองเห็นด้านความปลอดภัยหรือการตรวจสอบ

เงื่อนไขการใช้งานซอร์สโค้ดและใบอนุญาต โปรดดูที่ [LICENSE](https://github.com/FileUni/FileUni-Project/blob/main/LICENSE)

หากมีคำถามเกี่ยวกับการใช้งาน ใบอนุญาต หรือความร่วมมือ โปรดติดต่อ: `contact@fileuni.com`
